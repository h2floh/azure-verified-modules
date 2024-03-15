# To reproduce issue

```bash
az login
cd avm-nat-gateway
az deployment sub create --verbose --location swedencentral --template-file ./main.bicep
```