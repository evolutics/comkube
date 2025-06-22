use futures::StreamExt;
use futures::channel::mpsc;
use k8s_openapi::api::core::v1;
use kube::api;
use kube::api::Resource;
use kube::runtime::controller;
use kube::runtime::watcher;
use std::collections;
use std::io;
use std::io::BufRead;
use std::sync;
use std::thread;
use tokio::time;

#[derive(Debug, thiserror::Error)]
enum Error {
    #[error("Failed to create ConfigMap: {0}")]
    ConfigMapCreationFailed(#[source] kube::Error),
    #[error("MissingObjectKey: {0}")]
    MissingObjectKey(&'static str),
}

#[derive(
    kube::CustomResource, Debug, Clone, serde::Deserialize, serde::Serialize, schemars::JsonSchema,
)]
#[kube(group = "evolutics.info", version = "v1", kind = "ConfigMapGenerator")]
#[kube(shortname = "cmg", namespaced)]
struct ConfigMapGeneratorSpec {
    content: String,
}

/// Controller triggers this whenever our main object or our children changed
async fn reconcile(
    generator: sync::Arc<ConfigMapGenerator>,
    ctx: sync::Arc<Data>,
) -> anyhow::Result<controller::Action, Error> {
    let client = &ctx.client;

    let mut contents = collections::BTreeMap::new();
    contents.insert("content".to_string(), generator.spec.content.clone());
    let oref = generator.controller_owner_ref(&()).unwrap();
    let cm = v1::ConfigMap {
        metadata: api::ObjectMeta {
            name: generator.metadata.name.clone(),
            owner_references: Some(vec![oref]),
            ..api::ObjectMeta::default()
        },
        data: Some(contents),
        ..Default::default()
    };
    let cm_api = api::Api::<v1::ConfigMap>::namespaced(
        client.clone(),
        generator
            .metadata
            .namespace
            .as_ref()
            .ok_or_else(|| Error::MissingObjectKey(".metadata.namespace"))?,
    );
    cm_api
        .patch(
            cm.metadata
                .name
                .as_ref()
                .ok_or_else(|| Error::MissingObjectKey(".metadata.name"))?,
            &api::PatchParams::apply("configmapgenerator.kube-rt.evolutics.info"),
            &api::Patch::Apply(&cm),
        )
        .await
        .map_err(Error::ConfigMapCreationFailed)?;
    Ok(controller::Action::requeue(time::Duration::from_secs(300)))
}

/// The controller triggers this on reconcile errors
fn error_policy(
    _object: sync::Arc<ConfigMapGenerator>,
    _error: &Error,
    _ctx: sync::Arc<Data>,
) -> controller::Action {
    controller::Action::requeue(time::Duration::from_secs(1))
}

// Data we want access to in error/reconcile calls
struct Data {
    client: kube::Client,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    let client = kube::Client::try_default().await?;

    let cmgs = api::Api::<ConfigMapGenerator>::all(client.clone());
    let cms = api::Api::<v1::ConfigMap>::all(client.clone());

    tracing::info!("starting configmapgen-controller");
    tracing::info!("press <enter> to force a reconciliation of all objects");

    let (mut reload_tx, reload_rx) = mpsc::channel(0);
    // Using a regular background thread since tokio::io::stdin() doesn't allow aborting reads,
    // and its worker prevents the Tokio runtime from shutting down.
    thread::spawn(move || {
        for _ in io::BufReader::new(io::stdin()).lines() {
            let _ = reload_tx.try_send(());
        }
    });

    // limit the controller to running a maximum of two concurrent reconciliations
    let config = controller::Config::default().concurrency(2);

    controller::Controller::new(cmgs, watcher::Config::default())
        .owns(cms, watcher::Config::default())
        .with_config(config)
        .reconcile_all_on(reload_rx.map(|_| ()))
        .shutdown_on_signal()
        .run(reconcile, error_policy, sync::Arc::new(Data { client }))
        .for_each(|res| async move {
            match res {
                Ok(o) => tracing::info!("reconciled {:?}", o),
                Err(e) => tracing::warn!("reconcile failed: {}", e),
            }
        })
        .await;
    tracing::info!("controller terminated");
    Ok(())
}
