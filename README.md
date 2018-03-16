[![Gem Version](https://badge.fury.io/rb/itamae-mitsurin.svg)](http://badge.fury.io/rb/itamae-mitsurin)

Customized version of Itamae and plugin

## Concept

- Like more Chef
- Little attributes
- Support AWS Resource
- Running on the RakeTask

## Installation

```
$ gem install itamae-mitsurin
$ manaita init
```

## If you want to use the AWS Resources
```
$ aws configure
```

## Tips for git user
- Add this content to your `.gitignore`
```
tmp-nodes/
logs/
Project.json
!.keep
```

## Usage AWS Resource

```ruby
# recipe

aws_ebs_volume "ebs_name" do
  action [:create, :attach]
  region "ap-northeast-1"
  availability_zone "ap-northeast-1a"
  device '/dev/xvdb'
  volume_type 'standard'
  size 10
  instance_id 'i-xxxxxxx'
end
```

## Wiki
- [itamae-mitsurin wiki](https://github.com/kammy1231/itamae-mitsurin/wiki/itamae-mitsurin-wiki)

## Reference
- [itamae wiki](https://github.com/itamae-kitchen/itamae/wiki)
- [Serverspec host_inventory](http://serverspec.org/host_inventory.html)

## Contributing

If you have a problem, please [create an issue](https://github.com/kammy1231/itamae-mitsurin) or a pull request.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
