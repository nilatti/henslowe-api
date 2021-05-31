module CustomTokenResponse
  def body
    additional_data = {
      'userId' => @token.resource_owner_id # you have an access to the @token object
    }

    # call original `#body` method and merge its result with the additional data hash
    super.merge(additional_data)
  end
end
