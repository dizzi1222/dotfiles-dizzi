---
hostname: buganizer.corp.google.com
description: Google's internal issue tracker - Create and manage bugs and feature requests
---

# Tasks

## Create New Issue
- Navigate to https://buganizer.corp.google.com/ and use the "New issue" page
- Fill out all required fields (marked with asterisks)
- After submitting, verify the ticket was created by checking the page DOM
- For specific component IDs, navigate to https://buganizer.corp.google.com/issues/new?component={component_id}

## Find Component ID
- Access http://go/componentsearch to search for component names
- Search for the component name to find its ID
- If component name is unknown, ask the user for clarification
- Use the component ID in the new issue URL