#!/bin/sh

#  ci_post_clone.sh
#  SYKeyboard
#
#  Created by 서동환 on 6/9/26.
#  

set -eu

REPOSITORY_PATH="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
SECRETS_PATH="${REPOSITORY_PATH}/SYKeyboard/Resources/Configs/Secrets.xcconfig"
FIREBASE_PATH="${REPOSITORY_PATH}/Common/Firebase"

: "${GADApplicationIdentifier:?GADApplicationIdentifier 환경변수가 필요합니다.}"
: "${DeveloperEmail:?DeveloperEmail 환경변수가 필요합니다.}"
: "${FIREBASE_BUNDLE_ID:?FIREBASE_BUNDLE_ID 환경변수가 필요합니다.}"
: "${FIREBASE_PLIST_VERSION:?FIREBASE_PLIST_VERSION 환경변수가 필요합니다.}"
: "${FIREBASE_IS_ADS_ENABLED:?FIREBASE_IS_ADS_ENABLED 환경변수가 필요합니다.}"
: "${FIREBASE_IS_ANALYTICS_ENABLED:?FIREBASE_IS_ANALYTICS_ENABLED 환경변수가 필요합니다.}"
: "${FIREBASE_IS_APPINVITE_ENABLED:?FIREBASE_IS_APPINVITE_ENABLED 환경변수가 필요합니다.}"
: "${FIREBASE_IS_GCM_ENABLED:?FIREBASE_IS_GCM_ENABLED 환경변수가 필요합니다.}"
: "${FIREBASE_IS_SIGNIN_ENABLED:?FIREBASE_IS_SIGNIN_ENABLED 환경변수가 필요합니다.}"
: "${FIREBASE_DEBUG_API_KEY:?FIREBASE_DEBUG_API_KEY 환경변수가 필요합니다.}"
: "${FIREBASE_DEBUG_GOOGLE_APP_ID:?FIREBASE_DEBUG_GOOGLE_APP_ID 환경변수가 필요합니다.}"
: "${FIREBASE_DEBUG_GCM_SENDER_ID:?FIREBASE_DEBUG_GCM_SENDER_ID 환경변수가 필요합니다.}"
: "${FIREBASE_DEBUG_PROJECT_ID:?FIREBASE_DEBUG_PROJECT_ID 환경변수가 필요합니다.}"
: "${FIREBASE_DEBUG_STORAGE_BUCKET:?FIREBASE_DEBUG_STORAGE_BUCKET 환경변수가 필요합니다.}"
: "${FIREBASE_RELEASE_API_KEY:?FIREBASE_RELEASE_API_KEY 환경변수가 필요합니다.}"
: "${FIREBASE_RELEASE_GOOGLE_APP_ID:?FIREBASE_RELEASE_GOOGLE_APP_ID 환경변수가 필요합니다.}"
: "${FIREBASE_RELEASE_GCM_SENDER_ID:?FIREBASE_RELEASE_GCM_SENDER_ID 환경변수가 필요합니다.}"
: "${FIREBASE_RELEASE_PROJECT_ID:?FIREBASE_RELEASE_PROJECT_ID 환경변수가 필요합니다.}"
: "${FIREBASE_RELEASE_STORAGE_BUCKET:?FIREBASE_RELEASE_STORAGE_BUCKET 환경변수가 필요합니다.}"

# Secrets.xcconfig 파일 생성
echo "환경변수 참조 Secrets.xcconfig file 생성 시작"
mkdir -p "$(dirname "${SECRETS_PATH}")"
cat <<EOF > "${SECRETS_PATH}"

GADApplicationIdentifier = ${GADApplicationIdentifier}
DeveloperEmail = ${DeveloperEmail}

EOF

echo "환경변수 참조 Secrets.xcconfig file 생성 완료"

# GoogleService-Info.plist 파일 생성
create_google_service_info() {
    CONFIGURATION="$1"
    API_KEY="$2"
    GOOGLE_APP_ID="$3"
    GCM_SENDER_ID="$4"
    PROJECT_ID="$5"
    STORAGE_BUCKET="$6"
    OUTPUT_PATH="${FIREBASE_PATH}/${CONFIGURATION}/GoogleService-Info.plist"

    echo "${CONFIGURATION} GoogleService-Info.plist file 생성 시작"
    mkdir -p "$(dirname "${OUTPUT_PATH}")"
    /usr/bin/plutil -create xml1 "${OUTPUT_PATH}"
    /usr/bin/plutil -insert API_KEY -string "${API_KEY}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert GCM_SENDER_ID -string "${GCM_SENDER_ID}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert PLIST_VERSION -string "${FIREBASE_PLIST_VERSION}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert BUNDLE_ID -string "${FIREBASE_BUNDLE_ID}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert PROJECT_ID -string "${PROJECT_ID}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert STORAGE_BUCKET -string "${STORAGE_BUCKET}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert IS_ADS_ENABLED -bool "${FIREBASE_IS_ADS_ENABLED}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert IS_ANALYTICS_ENABLED -bool "${FIREBASE_IS_ANALYTICS_ENABLED}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert IS_APPINVITE_ENABLED -bool "${FIREBASE_IS_APPINVITE_ENABLED}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert IS_GCM_ENABLED -bool "${FIREBASE_IS_GCM_ENABLED}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert IS_SIGNIN_ENABLED -bool "${FIREBASE_IS_SIGNIN_ENABLED}" "${OUTPUT_PATH}"
    /usr/bin/plutil -insert GOOGLE_APP_ID -string "${GOOGLE_APP_ID}" "${OUTPUT_PATH}"
    /usr/bin/plutil -lint "${OUTPUT_PATH}"
    echo "${CONFIGURATION} GoogleService-Info.plist file 생성 완료"
}

create_google_service_info \
    "Debug" \
    "${FIREBASE_DEBUG_API_KEY}" \
    "${FIREBASE_DEBUG_GOOGLE_APP_ID}" \
    "${FIREBASE_DEBUG_GCM_SENDER_ID}" \
    "${FIREBASE_DEBUG_PROJECT_ID}" \
    "${FIREBASE_DEBUG_STORAGE_BUCKET}"

create_google_service_info \
    "Release" \
    "${FIREBASE_RELEASE_API_KEY}" \
    "${FIREBASE_RELEASE_GOOGLE_APP_ID}" \
    "${FIREBASE_RELEASE_GCM_SENDER_ID}" \
    "${FIREBASE_RELEASE_PROJECT_ID}" \
    "${FIREBASE_RELEASE_STORAGE_BUCKET}"
