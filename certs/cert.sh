# 내 서버 IP(3.39.23.131)를 인증서에 박아넣고 1년짜리 자체 서명 인증서를 만듭니다. 아래 명령어를 터미널에 통째로 복사해서 붙여넣으세요.
# 생성된 인증서와 키 파일을 ssl 폴더 하로 복사
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout server.key \
  -out server.crt \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=Siemens/CN=3.39.23.131" \
  -addext "subjectAltName=IP:3.39.23.131"

# cd ~/aihub/ssl
# 기존 파일들을 확실하게 프록시 표준 이름으로 복사
# sudo cp server.crt fullchain.pem
# sudo cp server.key privkey.pem

# DH 파라미터 파일 생성
openssl dhparam -out dhparam.pem 2048