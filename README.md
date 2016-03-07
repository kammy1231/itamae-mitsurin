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
$ mkdir project_dir
$ cd project_dir
$ manaita init
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

## Contributing

If you have a problem, please [create an issue](https://github.com/kammy1231/itamae-mitsurin) or a pull request.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
