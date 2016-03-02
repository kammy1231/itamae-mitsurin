[![Gem Version](https://badge.fury.io/rb/itamae-mitsurin.svg)](http://badge.fury.io/rb/itamae-mitsurin)

Customized version of Itamae and plugin

## Concept

- Like more Chef
- Little attributes
- Support AWS Resource

## Installation

```
$ gem install itamae-mitsurin
$ mkdir project_dir
$ cd project_dir
$ itamae-mitsurin init
```

## Usage AWS Resource

```ruby
# recipe

Aws.config[:region] = 'ap-northeast-1'

aws_ebs_volume "ebs_name" do
  action [:create, :attach]
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
