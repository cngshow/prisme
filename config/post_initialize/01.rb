module PrismeUtilities
  module RouteHelper
    include Rails.application.routes.url_helpers

    def self.route(url_or_path, **params)
      Rails.application.routes.url_helpers.send(url_or_path.to_sym, {protocol: PrismeConstants::URL::SCHEME, host: Socket.gethostname, relative_url_root: '/' + PrismeConstants::URL::CONTEXT, params: {security_token: CipherSupport.instance.generate_security_token}})
    end
  end
end

PrismeUtilities.write_vuid_db
at_exit do
  PrismeUtilities.remove_vuid_db
end