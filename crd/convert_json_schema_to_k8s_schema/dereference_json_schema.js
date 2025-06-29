import * as process from "process";
import $RefParser from "@apidevtools/json-schema-ref-parser";

let schema = await $RefParser.dereference("/dev/stdin");
process.stdout.write(JSON.stringify(schema, null, 2));
