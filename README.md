# Безпека в IoT — MQTT (Практична робота)

Усі експерименти виконані з реальним брокером Eclipse Mosquitto 2.0.18
(не імітація): запущено по черзі брокер без захисту (1883), з
автентифікацією (1884) та з TLS (8883), виконано реальні
`mosquitto_pub`/`mosquitto_sub`, згенеровано справжній CA і сертифікат,
перехоплено трафік через `tcpdump`.

## Структура

```text
task1_anon/        конфігурація анонімного брокера + перехоплений трафік
task2_auth/        конфігурація з автентифікацією, файл паролів, лог успішного доступу
task3_tls/         конфігурація TLS-брокера, дампи plaintext vs TLS трафіку
certs/             власний CA (ca.key/ca.crt) і підписаний серверний сертифікат
docs/              копії ключових доказів (traffic-логи, дампи, passwd, сертифікати)
```

## Відтворення

```bash
# Завдання 1 — анонімний брокер
mosquitto -c task1_anon/mosquitto.conf -v

# Завдання 2 — автентифікація
mosquitto_passwd -b -c task2_auth/passwd admin 'AdminStr0ng!Pass'
mosquitto_passwd -b   task2_auth/passwd sensor_device 'SensorKey_2024'
mosquitto_passwd -b   task2_auth/passwd actuator_light 'Actuator#Secure1'
mosquitto -c task2_auth/mosquitto.conf -v

# Завдання 3 — TLS
cd certs
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
  -subj "/C=UA/ST=Katowice/L=Katowice/O=IoT Security Lab/CN=Home IoT CA" -out ca.crt
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=localhost" -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256
cd ..
mosquitto -c task3_tls/mosquitto.conf -v
```

Повний опис, усі команди та висновки — у файлі звіту
`Практична_6_Безпека_в_IoT.docx`.
