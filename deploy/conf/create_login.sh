#!/usr/bin/env bash

# test mail
# download swaks
#curl http://www.jetmore.org/john/code/swaks/files/swaks-20181104.0.tar.gz --output ./swaks-20181104.0.tar.gz

# get api token
api_key=$(cat $CANVAS_API_KEY_FILE)

#URL="https://"${CANVAS_DOMAIN}"/api/v1/accounts/1/authentication_providers"
URL="http://localhost/api/v1/accounts/1/authentication_providers"

# Create SAML config
curl -s "$URL" \
     -F 'auth_type=saml' \
     -F 'position=1' \
     -F "idp_entity_id=${IDP_URL}/saml2/idp/metadata.php" \
     -F "log_in_url=${IDP_URL}/saml2/idp/SSOService.php" \
     -F "log_out_url=${IDP_URL}/saml2/idp/SingleLogoutService.php" \
     -F 'identifier_format=urn:oasis:names:tc:SAML:2.0:nameid-format:transient' \
     -F 'login_attribute=mail' \
     -F 'sig_alg=RSA-SHA256' \
     -F "certificate_fingerprint=${IDP_FINGERPRINT}" \
     -H "Authorization: Bearer $api_key"
