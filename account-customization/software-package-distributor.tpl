{
    "description" : "This document will distribute the package to all the targeted member accounts",
    "schemaVersion" : "0.3",
    "assumeRole" : "{{ AutomationAssumeRole }}",
    "parameters" : {
        "action" : {
        "description" : "(Required) Specify whether or not to install or uninstall the package.",
        "type" : "String",
        "allowedValues" : [ "Install", "Uninstall" ]
        },
        "installationType" : {
        "description" : "(Optional) Specify the type of installation. Uninstall and reinstall: The application is taken offline until the reinstallation process completes. In-place update: The application is available while new or updated files are added to the installation.",
        "type" : "String",
        "allowedValues" : [ "Uninstall and reinstall", "In-place update" ],
        "default" : "Uninstall and reinstall"
        },
        "name" : {
        "description" : "(Required) The package to install/uninstall.",
        "type" : "String",
        "allowedPattern" : "^arn:[a-z0-9][-.a-z0-9]{0,62}:[a-z0-9][-.a-z0-9]{0,62}:([a-z0-9][-.a-z0-9]{0,62})?:([a-z0-9][-.a-z0-9]{0,62})?:(package|document)\\/[a-zA-Z0-9/:.\\-_]{1,128}$|^[a-zA-Z0-9/:.\\-_]{1,128}$"
        },
        "version" : {
        "description" : "(Optional) The version of the package to install or uninstall. If you don't specify a version, the system installs the latest published version by default. The system will only attempt to uninstall the version that is currently installed. If no version of the package is installed, the system returns an error.",
        "type" : "String",
        "default" : ""
        },
        "additionalArguments" : {
        "description" : "(Optional) The additional parameters to provide to your install, uninstall, or update scripts.",
        "type" : "StringMap",
        "displayType" : "textarea",
        "default" : { },
        "maxChars" : 4096
        },
        "AutomationAssumeRole" : {
        "type" : "String",
        "description" : "The IAM role required to execute this document "
        },
        "InstanceId" : {
        "type" : "String",
        "default" : "*"
        }
    },
    "mainSteps" : [ {
        "name" : "sendCommandToDistributePackage",
        "action" : "aws:executeScript",
        "inputs" : {
        "Runtime" : "python3.7",
        "Handler" : "script_handler",
        "Script" : "import sys\nimport boto3\nimport json\nimport botocore\n\ndef script_handler(events, context):\n  client = boto3.client('ssm')\n  \n  instanceId = events['instanceId']\n  name = events['name']\n  action = events['action']\n  installationType = events['installationType']\n  version = events['version']\n  additionalArguments = events['additionalArguments']\n  packageConfigDetails = {}\n          \n  packageConfigDetails['name'] = [name]\n  packageConfigDetails['action'] = [action]\n  packageConfigDetails['installationType'] = [installationType]\n  \n  if not version:\n    print('No version specified')\n  else:\n    packageConfigDetails['version'] = [version]\n    \n  if not additionalArguments:\n    print('No additional arguments specified')\n  else:\n    packageConfigDetails['additionalArguments'] = [additionalArguments]\n            \n  ec2_response = client.describe_instance_information(\n    Filters=[\n        {\n            'Key': 'InstanceIds',\n            'Values': [\n                instanceId,\n            ]\n        },\n    ]\n  )\n  \n  if ec2_response['InstanceInformationList']:\n    ssm_pingstatus = ec2_response['InstanceInformationList'][0]['PingStatus']\n    if ssm_pingstatus == 'Online':\n      print(instanceId+' is eligible for this automation execution. Configuring package now...')\n      response = client.send_command(\n        InstanceIds=[\n                instanceId,\n            ],\n        DocumentName='AWS-ConfigureAWSPackage',\n        DocumentVersion='$DEFAULT',\n        Parameters=packageConfigDetails\n      )\n    else:\n      raise Exception(f'{instanceId} currently appears to be {ssm_pingstatus}')\n  else:\n    raise Exception(f'{instanceId} currently appears to be unavailable for this automation')\n",
        "InputPayload" : {
            "name" : "{{ name }}",
            "action" : "{{ action }}",
            "installationType" : "{{installationType}}",
            "version" : "{{ version }}",
            "additionalArguments" : "{{ additionalArguments }}",
            "instanceId" : "{{ InstanceId }}"
        }
        },
        "isEnd" : true
    } ]
}