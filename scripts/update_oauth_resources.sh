#!/bin/bash

# Requirements
# - curl
# - rg
# - jq

# Fetch iOS app versions
ios_version_list=$(curl -s "https://ipaarchive.com/app/usa/1064216828" | rg "(20\d{2}\.\d+.\d+) / (\d+)" --only-matching -r "Version \$1/Build \$2" | sort | uniq)

# Count the number of lines in the version list
ios_app_count=$(echo "$ios_version_list" | wc -l)

echo -e "Fetching \e[34m$ios_app_count iOS app versions...\e[0m"


# Specify the filename as a variable
filename="src/oauth_resources.rs"

# Add comment that it is user generated
echo "// This file was generated by scripts/update_oauth_resources.sh" > "$filename"
echo "// Rerun scripts/update_oauth_resources.sh to update this file" >> "$filename"
echo "// Please do not edit manually" >> "$filename"
echo "// Filled in with real app versions" >> "$filename"

# Open the array in the source file
echo "pub static IOS_APP_VERSION_LIST: &[&str; $ios_app_count] = &[" >> "$filename"

num=0

# Append the version list to the source file
echo "$ios_version_list" | while IFS= read -r line; do
  num=$((num+1))
  echo "    \"$line\"," >> "$filename"
  echo -e "[$num/$ios_app_count] Fetched \e[34m$line\e[0m."
done

# Close the array in the source file
echo "];" >> "$filename"

# Fetch Android app versions
page_1=$(curl -s "https://apkcombo.com/reddit/com.reddit.frontpage/old-versions/" | rg "<a class=\"ver-item\" href=\"(/reddit/com\.reddit\.frontpage/download/phone-20\d{2}\.\d+\.\d+-apk)\" rel=\"nofollow\">" -r "https://apkcombo.com\$1" | sort | uniq)
# Append with pages
page_2=$(curl -s "https://apkcombo.com/reddit/com.reddit.frontpage/old-versions?page=2" | rg "<a class=\"ver-item\" href=\"(/reddit/com\.reddit\.frontpage/download/phone-20\d{2}\.\d+\.\d+-apk)\" rel=\"nofollow\">" -r "https://apkcombo.com\$1" | sort | uniq)
page_3=$(curl -s "https://apkcombo.com/reddit/com.reddit.frontpage/old-versions?page=3" | rg "<a class=\"ver-item\" href=\"(/reddit/com\.reddit\.frontpage/download/phone-20\d{2}\.\d+\.\d+-apk)\" rel=\"nofollow\">" -r "https://apkcombo.com\$1" | sort | uniq)
page_4=$(curl -s "https://apkcombo.com/reddit/com.reddit.frontpage/old-versions?page=4" | rg "<a class=\"ver-item\" href=\"(/reddit/com\.reddit\.frontpage/download/phone-20\d{2}\.\d+\.\d+-apk)\" rel=\"nofollow\">" -r "https://apkcombo.com\$1" | sort | uniq)
page_5=$(curl -s "https://apkcombo.com/reddit/com.reddit.frontpage/old-versions?page=5" | rg "<a class=\"ver-item\" href=\"(/reddit/com\.reddit\.frontpage/download/phone-20\d{2}\.\d+\.\d+-apk)\" rel=\"nofollow\">" -r "https://apkcombo.com\$1" | sort | uniq)

# Concatenate all pages
versions="${page_1}"
versions+=$'\n'
versions+="${page_2}"
versions+=$'\n'
versions+="${page_3}"
versions+=$'\n'
versions+="${page_4}"
versions+=$'\n'
versions+="${page_5}"

# Count the number of lines in the version list
android_count=$(echo "$versions" | wc -l)

echo -e "Fetching \e[32m$android_count Android app versions...\e[0m"

# Append to the source file
echo "pub static ANDROID_APP_VERSION_LIST: &[&str; $android_count] = &[" >> "$filename"

num=0

# For each in versions, curl the page and extract the build number
echo "$versions" | while IFS= read -r line; do
  num=$((num+1))
  fetch_page=$(curl -s "$line")
  build=$(echo "$fetch_page" | rg "<span class=\"vercode\">\((\d+)\)</span>" --only-matching -r "\$1" | head -n1)
  version=$(echo "$fetch_page" | rg "<span class=\"vername\">Reddit (20\d{2}\.\d+\.\d+)</span>" --only-matching -r "\$1" | head -n1)
  echo "    \"Version $version/Build $build\"," >> "$filename"
  echo -e "[$num/$android_count] Fetched \e[32mVersion $version/Build $build\e[0m"
done

# Close the array in the source file
echo "];" >> "$filename"

# Retrieve iOS versions
table=$(curl -s "https://en.wikipedia.org/w/api.php?action=parse&page=IOS_17&prop=wikitext&section=31&format=json" | jq ".parse.wikitext.\"*\"" | rg "(17\.[\d\.]*)\\\n\|(\w*)\\\n\|" --only-matching -r "Version \$1 (Build \$2)")

# Count the number of lines in the version list
ios_count=$(echo "$table" | wc -l)

echo -e "Fetching \e[34m$ios_count iOS versions...\e[0m"

# Append to the source file
echo "pub static IOS_OS_VERSION_LIST: &[&str; $ios_count] = &[" >> "$filename"

num=0

# For each in versions, curl the page and extract the build number
echo "$table" | while IFS= read -r line; do
  num=$((num+1))
  echo "    \"$line\"," >> "$filename"
  echo -e "[$num/$ios_count] Fetched $line\e[0m"
done

# Close the array in the source file
echo "];" >> "$filename"

echo -e "\e[34mRetrieved $ios_app_count iOS app versions.\e[0m"
echo -e "\e[32mRetrieved $android_count Android app versions.\e[0m"
echo -e "\e[34mRetrieved $ios_count iOS versions.\e[0m"

echo -e "\e[34mTotal: $((ios_app_count + android_count + ios_count))\e[0m"

echo -e "\e[32mSuccess!\e[0m"
