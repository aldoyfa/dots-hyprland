#!/usr/bin/env bash
# Local addition (not part of upstream end4-pC).
# Chromium-based browsers only export a ~150px cover over MPRIS. For YouTube videos this
# finds the video and downloads its full-size thumbnail instead.
#   hires-art.sh <title> <artist> [page-url]   -> prints the path of the image, or nothing
# Results are cached in ~/.cache/quickshell/media/hires (an empty .miss file = "not found").

title="$1"; artist="$2"; url="$3"
[[ -z "$title" ]] && exit 1

cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/media/hires"
mkdir -p "$cache"
key="$(printf '%s|%s' "$title" "$artist" | md5sum | cut -d' ' -f1)"
out="$cache/$key.jpg"
miss="$cache/$key.miss"

[[ -s "$out" ]] && { echo "$out"; exit 0; }
# Don't retry a failed lookup more than once a day
[[ -n "$(find "$miss" -mtime -1 2>/dev/null)" ]] && exit 1

ua='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'
norm() { tr '[:upper:]' '[:lower:]' <<< "$1" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'; }

id=""
# 1. Exact: the player told us the page URL (e.g. via Plasma Browser Integration)
if [[ "$url" =~ (youtube\.com/watch\?([^#]*&)?v=|youtu\.be/|youtube\.com/shorts/)([A-Za-z0-9_-]{11}) ]]; then
    id="${BASH_REMATCH[3]}"
fi

# 2. Otherwise search by title + channel, and only accept a result whose channel (or exact
#    title) matches what the player reports, so a wrong video is never shown.
search() {
    curl -sL -m 15 --get --data-urlencode "search_query=$1" \
        -H 'Accept-Language: en' -A "$ua" https://www.youtube.com/results \
        | grep -o '"videoId":"[A-Za-z0-9_-]\{11\}"' | cut -d'"' -f4 | awk '!seen[$0]++' | head -5
}
if [[ -z "$id" ]]; then
    # "title channel" is the most precise query but sometimes returns nothing, so fall back to the title alone
    for query in "$title $artist" "$title"; do
        for c in $(search "$query"); do
            info="$(curl -s -m 10 "https://www.youtube.com/oembed?format=json&url=https://www.youtube.com/watch?v=$c")"
            c_author="$(jq -r '.author_name // empty' <<< "$info" 2>/dev/null)"
            c_title="$(jq -r '.title // empty' <<< "$info" 2>/dev/null)"
            if [[ -n "$artist" && "$(norm "$c_author")" == "$(norm "$artist")" ]] \
                || [[ "$(norm "$c_title")" == "$(norm "$title")" ]]; then
                id="$c"; break 2
            fi
        done
        [[ -z "$artist" ]] && break
    done
fi

if [[ -n "$id" ]]; then
    for size in maxresdefault sddefault hqdefault; do
        if curl -sfL -m 20 -A "$ua" "https://i.ytimg.com/vi/$id/$size.jpg" -o "$out.tmp" && [[ -s "$out.tmp" ]]; then
            mv "$out.tmp" "$out"
            rm -f "$miss"
            echo "$out"
            exit 0
        fi
    done
    rm -f "$out.tmp"
fi

touch "$miss"
exit 1
