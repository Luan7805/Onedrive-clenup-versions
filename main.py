#!/usr/bin/env python3

import subprocess
import json
import requests

REMOTE = "onedrive"
VERSIONS_TO_KEEP = 3

drive_id = json.loads(subprocess.check_output(["rclone", "config", "dump"]))[REMOTE]["drive_id"]


def get_access_token():
    command_output = subprocess.check_output(["rclone", "about", REMOTE + ":"])
    command_output = subprocess.check_output(["rclone", "config", "dump"])
    config_data = json.loads(command_output)
    token_data = config_data[REMOTE]["token"]
    access_token = json.loads(token_data)["access_token"]
    return access_token


def get_folder_id(folder_location):
    access_token = get_access_token()

    print(f"Searching {folder_location} folder id...")

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json"
    }

    url = f"https://graph.microsoft.com/v1.0/drives/{drive_id}/root:/{folder_location}"
    response = requests.get(url, headers=headers)
    response_data = json.loads(response.text)
    folder_id = response_data["id"]

    list_dir(folder_location, f"https://graph.microsoft.com/v1.0/drives/{drive_id}/items/{folder_id}/children")


def list_dir(folder_name, url):
    access_token = get_access_token()

    print(f"Listing directory: {folder_name}")

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json"
    }

    while True:
        response = requests.get(url, headers=headers)
        response_data = json.loads(response.text)

        for item in response_data["value"]:
            item_type = "file" if item.get("file") else "directory"
            item_id = item["id"]
            item_name = item["name"]

            if item_type == "file":
                get_versions(item_id, item_name)
            else:
                list_dir(f"{folder_name}/{item_name}", f"https://graph.microsoft.com/v1.0/drives/{drive_id}/items/{item_id}/children")

        next_url = response_data.get("@odata.nextLink")
        if not next_url:
            break
        url = next_url


def get_versions(item_id, file_name):

    access_token = get_access_token()

    print(f"Checking versions for: {file_name}")

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json"
    }

    url = f"https://graph.microsoft.com/v1.0/drives/{drive_id}/items/{item_id}/versions"
    response = requests.get(url, headers=headers)
    response_data = json.loads(response.text)

    version_ids = [version["id"] for version in response_data["value"]]
    version_ids_to_delete = version_ids[VERSIONS_TO_KEEP:]

    for version_id in version_ids_to_delete:
        print(f"Deleting version: {version_id}")
        delete_url = f"https://graph.microsoft.com/v1.0/drives/{drive_id}/items/{item_id}/versions/{version_id}"
        requests.delete(delete_url, headers=headers)


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python script.py <folder_location>")
        exit(1)

    get_folder_id(sys.argv[1])
