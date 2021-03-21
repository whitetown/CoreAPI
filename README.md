# SwiftCoreAPI

*A light-weight swift network library*
--


Simple GET request without parsing:

```swift
let resource = APIResource(path: "simple-get")

let api = APIService().base("https://coreapi.free.beeceptor.com/")
api.load(resource) { (json, data) -> NSDictionary? in
    return json as? NSDictionary
} completion: { (result) in
    print(result)
}
```

Simple GET request to get user (comforms to Decodable)

```swift
let resource = APIResource(path: "user")
let api = APIService().base("https://coreapi.free.beeceptor.com/")
api.load(resource, User.self) { (result) in
    print(result)
}
```

More complex example. Subclass the original APIService, set default params, add logging:

```swift
class MyAPIService: APIService {

    override init() {
        super.init()
        initialize()
    }

    func initialize() {
        self
            .base("https://coreapi.free.beeceptor.com/")
            .headers(values: ["api-key": "some-value"])
            .onLog { (value) in
                print(value)
            }
    }

    func makePost(completion: @escaping (Result<NSDictionary,Error>)->Void) {
        let resource = POST(path: "custom").body(["key":"value"])
        self.load(resource) { (json, data) -> NSDictionary? in
            return json as? NSDictionary
        } completion: { (result) in
            completion(result)
        }
    }

    func anotherExample(completion: @escaping (Result<Status,Error>)->Void) {
        let payload = User(id: 5, name: "Test")
        let resource = POST(path: "custom").payload(payload)

        self.load(resource, Status.self) { (result) in
            completion(result)
        }
    }
}

```
then you can use it as:
```swift
let customAPI = MyAPIService()
///

self.customAPI.makePost { (result) in
    print(result)
}
self.customAPI.anotherExample { (result) in
    print(result)
}
```

The core idea:
1. describe a resource
2. call service

both APIResource and APIService highly customisable, support chaining for parameters

```swift
let resource = APIResource()

resource
    .path("users")
    .post()
    .header("value", for: "key")
    .data(data)
//  .body(["key1": "value", "key2": 42])
//  .payload(EncodableModel())
    .query(["limit": 100, "offset": 0])

```


```swift
let service = APIService()

service
    .base(my_api_base_url)
    .headers(["value": "key"])
    .onLog({ value in 
        print(value)
    })
    .onError401({ url in
        //i.e. refresh token
        //then service.resume()
        //or
        //service.cancelAllRequests()
    })
    .onSignature({ (path) -> [String : String] in
        return ["Authorization": "Bearer xxxxxxx"]
    })
```

:-)
