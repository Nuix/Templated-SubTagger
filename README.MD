Templated Sub-Tagger
====================

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) ![This script was last tested in Nuix 9.10](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-9.10-green.svg)

View the GitHub project [here](https://github.com/Nuix/Templated-SubTagger) or download the latest release [here](https://github.com/Nuix/Templated-SubTagger/releases).

# Overview

Imagine that you have a review process that tags items in a Nuix case that are relevant with a tag named `Relevant`.  Now you would like to apply sub-tags based upon the kind of the tagged items:
- `Relevant|Emails`
- `Relevant|Containers`
- `Relevant|Chat Conversations`

To accomplish this manually, you would need to search for each tag and each possible kind and then apply the appropriate sub-tag to just those items.  While feasible to do by manually, this is time consuming and possibly error prone.  This script aims to help with this process by allowing to select one or more tags.  The items responsive to each of the selected tags then has additional tags applied to the them based on a template string you supply.  The above example could be accomplished by selecting `Relevant` as the input tag and supplying a template string of `{input_tag}|{kind_friendly}`.  See below for more details regarding available place holders.

## Place Holders

| Place Holder | Description |
|--------------|-------------|
| `{input_tag}` | The specified input tag which brought found this item for processing by this script. Note that this place holder is not required. |
| `{type}` | The item's type name as obtained by `ItemType.getLocalisedName` |
| `{mime_type}` | The item's mime type as obtained by `ItemType.getName` |
| `{kind}` | The item's kind name as obtained by `ItemType.getKind.getName` |
| `{kind_friendly}` | The item's kind name as obtained by `ItemType.getKind.getLocalisedName` |
| `{custodian}` | The item's assigned custodian or **NO_CUSTODIAN** for items without a custodian assigned |
| `{evidence_name}` | The name of the evidence the item belongs to. |
| `{item_date_short}` | The item's item date formatted `YYYYMMDD` or **NO_DATE** for items without an item date. |
| `{item_date_long}` | The item's item date formatted `YYYYMMdd-HHmmss` or **NO_DATE** for items without an item date. |
| `{item_date_year}` | The item's item date 4 digit year or **NO_DATE** for items without an item date. |
| `{item_date_month}` | The item's item date 2 digit month or **NO_DATE** for items without an item date. |
| `{item_date_day}` | The item's item date 2 digit day of the month or **NO_DATE** for items without an item date. |
| `{top_level_guid}` | The GUID of the provided item's top level item or **ABOVE_TOP_LEVEL** for items which are above top level. |
| `{top_level_name}` | The name (via `Item.getLocalisedName`) of the provided item's top level item or **ABOVE_TOP_LEVEL** for items which are above top level. |
| `{top_level_kind}` | The kind (via `ItemType.getKind.getName`) of the provided item's top level item or **ABOVE_TOP_LEVEL** for items which are above top level. |
| `{original_extension}` | The original extension as obtained from Nuix via `Item.getOriginalExtension` or **NO_ORIGINAL_EXTENSION** for items where Nuix does not have an original extension value. |
| `{corrected_extension}` | The corrected extension as obtained from Nuix via `Item.getCorrectedExtension` or **NO_CORRECTED_EXTENSION** for items where Nuix does not have a corrected extension value. |

These are less useful in this context, but underlying PlaceholderResolver can resolve them, so they are documented here for completeness:

| Place Holder | Description |
|--------------|-------------|
| `{guid}` | The item's GUID. |
| `{guid_prefix}` | Characters 0-2 of the item's GUID. Useful for creating sub-groupings based on GUID. |
| `{guid_infix}` | Characters 3-5 of the item's GUID. Useful for creating sub-groupings based on GUID. |
| `{name}` | The item's name as obtained by Item.getLocalisedName |
| `{md5}` | The item's MD5 or NO_MD5 for items without an MD5 value |

# Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory


# Cloning this Repository

This script relies on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the script.

This script also relies on code from [SuperUtilities](https://github.com/Nuix/SuperUtilities).  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of SuperUtilities.jar by either:
1. Building it from [the source](https://github.com/Nuix/SuperUtilities)
2. Downloading an already built JAR file from the [SuperUtilities releases](https://github.com/Nuix/SuperUtilities/releases)

Once you also have a copy of SuperUtilities.jar, make sure to include it in the same directory as the script.

# License

```
Copyright 2023 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
