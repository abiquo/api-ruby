module AbiquoAPIClient
  ##
  # Common error exception
  #
  class Error < Exception; end
  
  ##
  # InvalidCredentials exception.
  # Raised whenever the API responds with
  # a 401 HTTP code.
  #
  class InvalidCredentials < AbiquoAPIClient::Error; end
  
  ##
  # Forbidden exception
  # Raised whenever the API responds with
  # a 403 HTTP code.
  #
  class Forbidden < AbiquoAPIClient::Error; end
  
  ##
  # Badrequest exception
  # Raised whenever the API responds with
  # a 400 or 406 HTTP code.
  #
  class BadRequest < AbiquoAPIClient::Error; end

  ##
  # NotFound exception
  # Raised whenever the API responds with
  # a 404 HTTP code.
  #
  class NotFound < AbiquoAPIClient::Error; end
  
  ##
  # UnsupportedMediaType exception
  # Raised whenever the API responds with
  # a 415 HTTP code.
  #
  class UnsupportedMediaType < AbiquoAPIClient::Error; end
end