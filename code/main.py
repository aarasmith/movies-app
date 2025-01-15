import requests
import boto3
import json
import datetime
from typing import List, Dict, Union

def main():
    payload = fetch_api_data()
    write_json_to_s3(payload)

def fetch_api_data() -> List[Dict]:
    res = requests.get('https://api.sampleapis.com/movies/animation')
    return res.json()

def connect_to_s3():
    s3 = boto3.client('s3')
    return s3

def write_json_to_s3(json_object: Union[Dict, List], overwrite: bool = False) -> None:
    """Write the API request payload to s3
    
    Args:
        json_object (Dict/List): Dictionary or list of dicts obtained from the fetch_api_data() function
        overwrite (bool): If true, writes the file as 'movies.json', otherwise adds current time to prevent overwriting
    """
    
    s3 = connect_to_s3()
    if not overwrite:
        key = f"movies_{str(datetime.datetime.now())}.json"
    else:
        key = "movies.json"

    s3.put_object(
        Body=json.dumps(json_object),
        Bucket='treatwell',
        Key=key
    )

if __name__ == "__main__":
    main()