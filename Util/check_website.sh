#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <website_url>"
    exit 1
fi

website_url="$1"

# Use curl to make a simple HTTP GET request
response=$(curl -Is "$website_url" | head -n 1)

# Check if the response contains "200 OK" indicating a successful request
if [[ "$response" =~ 200\ OK ]]; then
    echo "Website is working: $website_url"
    exit 0
else
    echo "Website is not accessible: $website_url"
    exit 1
fi

