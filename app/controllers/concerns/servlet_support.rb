module ServletSupport

  SERVLET_REQUEST = 'java.servlet_request'

  def servlet_response
    request.headers[SERVLET_REQUEST]
  end

  #returns the host beneath the proxy
  def true_address
    addr = servlet_response.getLocalName
    $log.debug("True address/hostname is #{addr}")
    addr
  end

  #returns the port beneath the proxy
  def true_port
    port = servlet_response.getLocalPort
    $log.debug("True port is #{port}")
    port
  end

  #returns the scheme beneath the proxy
  def secure?
    s = servlet_response.isSecure
    $log.debug("is https? #{s}")
    s
  end

end