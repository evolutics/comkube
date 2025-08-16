use super::kompose;
use kube::Resource;
use kube::api;
use kube::api::ResourceExt;

pub fn get(compose_app: &super::ComposeApplication) -> Vec<api::DynamicObject> {
    let owner_reference = compose_app.controller_owner_ref(&()).unwrap();

    // TODO: Report Kompose errors via Compose app object instead of crashing.
    let documents = kompose::convert(&serde_json::to_string(&compose_app.spec).unwrap()).unwrap();

    documents
        .into_iter()
        .map(|document| {
            let mut object = serde_yaml::from_value::<api::DynamicObject>(document).unwrap();
            object
                .labels_mut()
                .insert("app.kubernetes.io/managed-by".into(), "Comkube".into());
            object.owner_references_mut().push(owner_reference.clone());
            object
        })
        .collect()
}
