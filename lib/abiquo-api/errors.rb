module AbiquoAPIClient
  class Error < Exception; end
  class InvalidCredentials < AbiquoAPIClient::Error; end
  class Forbidden < AbiquoAPIClient::Error; end
  class BadRequest < AbiquoAPIClient::Error; end
  class UnsupportedMediaType < AbiquoAPIClient::Error; end
end