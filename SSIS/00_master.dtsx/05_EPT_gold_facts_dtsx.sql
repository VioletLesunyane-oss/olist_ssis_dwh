--01. General
Name: EPT_gold_facts_dtsx
Description: Execute Package Task

--02. Package
ReferenceType: Project Reference
PackageNameFromProjectReference: 03_gold_facts.dtsx
Password: *leave blank*
ExecuteOutProcess: False

--03. Parameter Bindings
Child package parameter: p_batch_id
Binding parameter or variable: user::batch_id