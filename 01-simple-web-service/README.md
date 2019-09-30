This template shows a simple web server built with an API gateway, a Lambda function, and a dynamoDB

Posting to the API gateway "/addFramework
with a body of 
{
    "GithubURL":"https://github.com/vuejs",
    "Year": "2013"
}
should add an item to the dynamoDB table.

TODO:
Codify or extract all vars (region)
add read functionality
