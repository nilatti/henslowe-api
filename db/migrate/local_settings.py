import os
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'msbmi%!g_9e83gvfqt!303lkn32yxmw89bg&f_$ijdiy#^c8k$'

DEBUG = True

# Database
# https://docs.djangoproject.com/en/3.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}

AK_PASSWORD = 'yuMn,NuG9mfHXgm9'
AK_BASEURL = 'https://act.moveon.org'
AK_USER = 'ganymede-admin'
AK_TEST = False

ALLOWED_HOSTS = ['localhost',
                 'ganymede-stage.moveon.org', 'ganymede.moveon.org']


# static files deployment settings
AWS_REGION = 'us-east-1'
AWS_ACCESS_KEY_ID = "AKIA3AO6RW2Y4QPFF7UK"
AWS_SECRET_ACCESS_KEY = "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"
AWS_S3_BUCKET_NAME_STATIC = "s3.moveon.org"
# ganymede-prod or ganymede-stage for staging site
AWS_S3_KEY_PREFIX_STATIC = "ganymede-prod"
AWS_S3_FILE_OVERWRITE_STATIC = True
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = '754069186605-3q22h80mg425lda2q902a5368f26ccql.apps.googleusercontent.com'
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = 'G1x8fxRH_AaUwqTRv-MTR_vO'
SOCIAL_AUTH_GOOGLE_OAUTH2_WHITELISTED_EMAILS = ['alisha.huber@gmail.com']
SOCIAL_AUTH_GOOGLE_OAUTH2_WHITELISTED_DOMAINS = ['moveon.org', 'kcactf2.org']
# Internationalization
# https://docs.djangoproject.com/en/3.0/topics/i18n/'
CALL_CENTER_USER_ID = "2"
CALL_CENTER_IP_ADDRESS = ["127.0.0.1", "0.0.0.0"]
LANGUAGE_CODE = 'en-us'
ENCRYPT_KEY = "F7ljWIfRedfuHgzY"
