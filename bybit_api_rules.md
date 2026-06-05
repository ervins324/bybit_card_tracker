

# Bybit Card API — Integration Documentation (V5)

This document provides a technical overview and requirements for developing and integrating with the Bybit Card API.

---

## 1. General Information and Restrictions

> ⚠️ **Important regarding GEO-restrictions:** > IP addresses located in the US or Mainland China are restricted. Requests originating from these locations will return a `403 Forbidden` error.

### Base Endpoints

* **Testnet:** `https://api-testnet.bybit.com`
* **Mainnet:** `https://api.bybit.com` or `https://api.bytick.com`

#### Regional Mainnet Endpoints

* Netherlands: `https://api.bybit.nl`
* Turkey: `https://api.bybit.tr`
* Kazakhstan: `https://api.bybit.kz`
* Georgia: `https://api.bybitgeorgia.ge`
* United Arab Emirates: `https://api.bybit.ae`
* EEA (EU): `https://api.bybit.eu` *(EU site API only supports "Connect to Third-Party Applications" feature for API broker users)*
* Indonesia: `https://api.bybit.id`

---

## 2. Authentication and HTTP Headers

To generate API keys, please visit the Bybit Testnet or Mainnet personal account.

### API Key Types

1. **System-generated (HMAC):** The system generates a public and private key pair. Requests are signed using the HMAC-SHA256 algorithm.
2. **Auto-generated (RSA):** Keys are created on the developer's side using `api-rsa-generator`. Only the public key is provided to Bybit. Requests are signed using the RSA-SHA256 algorithm.

### Required HTTP Headers

* `X-BAPI-API-KEY` — Your API key.
* `X-BAPI-TIMESTAMP` — UTC timestamp in milliseconds.
* `X-BAPI-SIGN` — The final signature derived from the request.
* `X-BAPI-RECV-WINDOW` — Request validity window in milliseconds (default: `5000`).
* `X-Referer` / `Referer` — Required for broker accounts only.

> 📝 **Timestamp Rule:** `server_time - recv_window <= timestamp < server_time + 1000`. It is highly recommended to use local device time and keep it NTP-synchronized.

---

## 3. Signature Generation

### Constructing the String to Sign

* **GET Requests:** `timestamp + api_key + recv_window + queryString`
* **POST Requests:** `timestamp + api_key + recv_window + jsonBodyString`

### Signature Algorithm

* **HMAC_SHA256:** Convert the output to a lowercase HEX string.
* **RSA_SHA256:** Convert the output to a Base64 string.

#### GET Request Example

```text
String to sign: 1658384314791XXXXXXXXXX5000category=option&symbol=BTC-29JUL22-25000-C
HMAC Signature: 410e0f387bafb7afd0f1722c068515e09945610124fa11774da1da857b72f30b

```

---

## 4. Common Response Format

All API responses are returned in JSON format with a standardized structure:

| Parameter | Type | Description |
| --- | --- | --- |
| `retCode` | number | Business return code (`0` for success, non-zero for failure) |
| `retMsg` | string | Success/Error message ("OK", "SUCCESS", or error details) |
| `result` | object | Business data payload |
| `retExtInfo` | object | Extended info (usually `{}`) |
| `time` | number | Current server timestamp (ms) |

---

## 5. Endpoints Reference

### 5.1. Query Asset Records

Query card transaction history with pagination and various filters.

* **HTTP Method:** `POST`
* **Path:** `/v5/card/transaction/query-asset-records`

#### Request Parameters (Body / Query)

* `statusCode` (string, false) — Transaction status code: `0` (Pending), `1` (Cleared), `2` (Declined).
* `limit` (integer, false) — Number of items per page (1-500, default: 100).
* `page` (integer, false) — Page number (min: 1).
* `pan4` (string, false) — Last 2 or 4 digits of the card number.
* `createBeginTime` / `createEndTime` (integer, false) — Unix ms timestamps.
* `merchName` (string, false) — Merchant name (supports fuzzy search).
* `type` (string, false) — `SIDE_QUERY_AUTH` (Authorization), `SIDE_QUERY_FINANCIAL` (Clearing), `SIDE_QUERY_REFUND` (Refund).
* `txnId` / `orderNo` / `cardToken` (string, false) — Identifiers for exact matching.

#### Structure of `result.data` (Array)

* `pan4` / `pan6` — Masked card number details.
* `tradeStatus` — `0` (In Progress), `1` (Completed), `2` (Declined), `3` (Reversal).
* `side` — Transaction type (e.g., `1`: Auth, `3`: Transaction, `5`: Refund, `13`: ATM Withdrawal).
* `basicAmount` / `basicCurrency` — Total transaction amount and currency code.
* `transactionAmount` / `transactionCurrency` — Amount and currency code before tax.
* `txnCreate` — Transaction creation time (Unix ms).
* `declinedReason` — Populated only when the transaction is declined.
* `status` — `-1` (Init), `0` (Pending), `1` (Success), `2` (Fail).

---

### 5.2. Query Point Balance

Query the user's card reward point balance, frozen points, and account status.

* **HTTP Method:** `POST`
* **Path:** `/v5/card/reward/points/balance`
* **Request Parameters:** None

#### Key Response Parameters (`result`)

* `accountId` (string) — Account ID.
* `availablePoint` (number) — Available reward points.
* `pendingPoint` (number) — Pending (frozen) points.
* `status` (string) — Account status (e.g., "active").
* `settlementPeriod` (integer) — Settlement period.

---

### 5.3. Query Point Records

Query the transaction history of the user's card reward points.

* **HTTP Method:** `POST`
* **Path:** `/v5/card/reward/points/records`

#### Request Parameters

* `type` (string, false) — Point type filter.
* `pageSize` / `pageNo` (integer, false) — Pagination settings (default size: 10).
* `startTime` / `endTime` (integer, false) — Unix timestamps.
* `side` (string, false) — Point direction: `1` (Earn points), `2` (Deduct points).
* `outOrderId` / `bizId` / `bizTxnId` (string, false) — Reference order IDs.

#### Key Elements in `result.data` (Array)

* `point` — Point amount.
* `type` — Operation type (e.g., `CASHBACK`).
* `transactionAmount` / `basicCurrency` — Original transaction amount and currency.
* `payFiatAmount` / `transactionCurrencyAmount` — Amount paid with fiat vs crypto.

---

### 5.4. Query Tier Info

Query the user's reward tier level and spending limit details.

* **HTTP Method:** `POST`
* **Path:** `/v5/card/reward/points/tier`
* **Request Parameters:** None

#### Key Response Parameters (`result`)

* `usedLimit` (string) — Used spending limit in USD (calculated as `points * 0.002`).
* `limit` (string) — Total spending limit.
* `tier` (string) — User tier level (e.g., `GOLD`).
* `autoCashback` (boolean) — Indicates if automatic cashback is enabled.

---

### 5.5. Query Mall Item List

Query items and vouchers available for redemption in the reward mall.

* **HTTP Method:** `POST`
* **Path:** `/v5/card/reward/mall/item/list`

#### Request Parameters

* `pageNo` / `pageSize` (integer, false).
* `itemType` (integer, false) — `1` (Virtual item), `2` (Physical item).
* `itemBizType` (integer, false) — `1` (POINTS), `2` (CURRENCY).
* `orderBy` (integer, false) — `1` (Priority), `2` (Listing time), `3` (Price).
* `asc` (boolean, false) — True for ascending order sorting.

#### Key Elements in `result.data` (Array)

* `itemId` / `itemName` — Item ID and display name.
* `price` / `discountPrice` — Base and discounted price in points.
* `totalNum` / `redeemNum` — Total inventory and total redeemed quantity.
* `currency` — Settlement asset type (e.g., `POINT`).

---

### 5.6. Query Cashback Detail

Query specific details and status of a cashback redemption order.

* **HTTP Method:** `POST`
* **Path:** `/v5/card/reward/point/cashback/detail`

#### Request Parameters

* `bizTxnId` (**string, true**) — Unique business transaction ID.

#### Key Response Parameters (`result`)

* `points` — Redeemed point amount.
* `amt` / `ccy` — Cashback value and target asset ticker (e.g., `1.00`, `USDT`).
* `ccyType` — Asset class (`CRYPTO` or `FIAT`).
* `orderShowStatus` — UI display status: `NO_PAY`, `ORDER_PENDING_SHOW`, `ORDER_SUCCESS`, `ORDER_FAIL`.