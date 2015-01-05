# Abiquo API client for Ruby

Basic API browsing and raw object manipulation for Ruby.

## Client object

The client object contains 3 objects that allow API browsing.

- **user.** The user object returned by the ```/api/login``` call.
- **enterprise.** The user's enterprise link to be used in new objects.
- **properties.** A hash containing all the system properties in the system. Useful to get default values for some objects (ie. VLAN parameters in VDC creation).

## Link object

Represents an Abiquo API Link. Issuing ```get``` on them will retrieve link destination. This allows for things like:

```ruby
vapp = vdc.link(:virtualappliances).get.first
```

## Generic model object

This is used to map Abiquo API objects.

## Examples

### Browse the API

#### Initialize connection

```ruby
a = AbiquoClient.new(:abiquo_api_url => 'https://10.60.13.40/api', 
                     :abiquo_username => "admin", 
                     :abiquo_password => "xabiquo")
```


#### User object

Is the User object returned by the API at login. You can browse the links provided like:

```ruby
a.user

vm = a.user.link(:virtualmachines).get.first

vm.name
=> "ABQ_6b6d9856-c05f-425e-8916-1ff7de1683e3"

vm.id
=> 18
```

### Create a VDC using an existing one as reference

#### Initialize connection

```ruby
a = AbiquoClient.new(:abiquo_api_url => 'https://10.60.13.40/api', 
                     :abiquo_username => "admin", 
                     :abiquo_password => "xabiquo")
```

#### Create a Link object to issue a request

```ruby
l = AbiquoClient::Link.new(:href => '/api/cloud/virtualdatacenters', 
              :type => 'application/vnd.abiquo.virtualdatacenters+json')
```

#### Get on the link

```ruby
v = a.get(l).first
```

#### Create a new object

```ruby
v1 = a.new_object(:name => "vdctest", 
                  :hypervisorType => "VMX_04", 
                  :vlan => v.vlan, 
                  :links => [v.link(:location), a.enterprise])
v1.vlan.delete("links")
v1.vlan.delete("id")
v1.vlan.delete("tag")
```

#### Create a link where to post data

```ruby
l1 = AbiquoClient::Link.new(:href => '/api/cloud/virtualdatacenters', 
              :type => 'application/vnd.abiquo.virtualdatacenter+json')
```

#### Post data

```ruby
v2 = a.post(l1, v1)
```

#### Modify the created object

```ruby
v2.name = "SomeValue"
v2 = a.put(v2.edit, v2)
```

Or:

```ruby
v2.name = "SomeValue"
v2.update
```

#### Delete it

```ruby
a.delete(v2.edit)
```

Or:

```ruby
v2.delete
```
