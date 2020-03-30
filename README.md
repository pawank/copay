# copay
CoPay App


## API

All API response returning JSON back to the caller must be of type 
```
{
	"status": true,
	"code": "200",
	"message": "",
	"data": {
  .....
	}
}
```
for success and 
```
{
	"status": true,
	"code": "200",
	"message": "",
	"data": {
	}
}
``` 
for failure. 

### Login

POST `/api/v1/login` 
Request:
```
{
	"version": "1.0",
	"username": "username or email",
	"password": "sample"
}
```

Response:
```
{
	"status": true,
	"code": "200",
	"message": "",
	"data": {
		"session": "1aecd7cf-c528-4fcc-b816-4b181d2fc2a0",
		"userId": "6aecd7cf-c528-4fcc-b816-4b181d2fc2a0",
		"name": "Pawan",
		"email": "pawan@gmail.com",
		"mobile": "9797987887",
		"avatarUrl": "/download/cache/files/pawan/aa6cec75-f632-45fc-ac7e-31356fd8c999/pawan kumar.jpg",
		"role": "User",
		"dates": {
			"createdOn": "2020-03-30 10:00:00",
			"updatedBy": "6aecd7cf-c528-4fcc-b816-4b181d2fc2a0",
			"isActive": true
		}
	}
}
```

All subsequent API must check for `X-Auth-Token` header key for the `session` value from data object. 
The expiry of session to be handled at the server for now for the MVP.

Rest all API are following convention mentioned in the doc: https://github.com/typicode/json-server. 
