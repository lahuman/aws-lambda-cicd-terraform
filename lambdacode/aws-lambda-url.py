from bs4 import BeautifulSoup
import requests
import boto3

url="https://lahuman.github.io/"
page = requests.get(url)


def lambda_handler(event, context):
    try:
        print("This is your first lambda code deployed by terraform and codepipeline.")
        soup = BeautifulSoup(page.content, "html.parser")
        print(soup.title.string)
    except Exception as e:
        print(e)
