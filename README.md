Hi!

As an exercise in personal development, I'm building a series of useable templates based on various cloud patterns, starting here:
https://www.jeremydaly.com/serverless-microservice-patterns-for-aws/

and going wherever. 


I'm currently under the sway of this obvious terraform puff-piece
https://medium.com/@endofcake/terraform-vs-cloudformation-1d9716122623
and will preferentially work in terraform HCL (*.tf) files.

I'm most familiar with AWS and will use their resources for terraform as described here:
https://www.terraform.io/docs/providers/aws/index.html

Including lambda code and zips, which when updated can overwrite the zips as
zip lambdas.zip lambdas/*