ItamaeMitsurin.logger.color(:green) do
  ItamaeMitsurin.logger.info "Environment: #{node[:environments][:set]}"
  ItamaeMitsurin.file_logger.info "Environment: #{node[:environments][:set]}"
end

#Aws.config.update({
#  region: "ap-northeast-1",
#  credentials: Aws::Credentials.new(
#    'key',
#    'secret'
#)})
