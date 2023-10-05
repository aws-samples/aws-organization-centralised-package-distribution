**Overview**

**Centralized-distribution-managment in an AWS Organization**

This Solution will demonstrate how you can build a solution using Terraform for organizations with a large number of instances. You can use this solution to simplify the process of managing the installation of software and execute any specific scripts on the instances across all of your member accounts within an AWS Organization with minimal effort.

This solution works for Amazon/Linux/window instances managed by AWS System manager. This solution can be used by administration team for installing security scanning softwares like CrowdStrike, SentinelOne & Monitoring Tool CloudWatch agent , Datadog agent, AppDynamics agent.

**Prerequisites**

The following prerequisites need to be completed to deploy this solution.

A Distributor package  with the software to be installed

Terraform v1.4.6+ Configuration. 

SSM managed EC2 Instances with basic permission to S3 in target account

AWS Control Tower Landing Zone Setup

Account Factory for Terraform (Optional) 

**Architecture**

This terraform code will deploy below architeture

<img width="1199" alt="Screenshot 2023-10-05 at 3 20 56 PM" src="https://github.com/aws-samples/aws-organization-centralised-package-distribution/assets/65273458/f24f13fb-7462-4f80-872e-a629b37667ca">




**Deployment**

This Terraform script deploys the following resources:

- IAM Role & IAM policies
- This Terraform script deploys the following resources:
after deploying automation documnets and package create AWS Association 
- To shedule Association add crone in the association.tf


**Solution Workflow**

- As per above solution architecture diagram , the solution workflow explained below (each step below corresponds to step in architecture diagram)
- As per above solution architecture diagram, the solution workflow explained below (each step below corresponds to step in architecture diagram)

- By running the solution from a centralized account, we will upload our packages or software along with deployment steps to AWS S3, 

- To shedule Association add crone in the association.tf
 
- This solution uses the management account within AWS Organizations, but you can also designate an account (delegated administrator) to manage this on behalf of the organization by Register a delegated administrator.


**Security**

See [SECURITY]([centralized-distribution-managment-in-an-aws-organization/-/blob/main/SECURITY.md]) for more information.

**License**

This library is licensed under the MIT-0 License. See the Licence [LICENCE]([https://github.com/aws-samples/aws-organization-centralised-package-distribution/blob/main/LICENSE])
 file.
