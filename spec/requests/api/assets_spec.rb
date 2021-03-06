# coding: UTF-8

require 'spec_helper'

describe "Assets API" do

  before(:all) do
    @user = create_user(:username => 'test', :email => "client@example.com", :password => "clientex")
    @user.set_map_key
    AWS.stub! # Live S3 requests tested on the model spec
  end

  before(:each) do
    delete_user_data @user
    host! 'test.localhost.lan'
  end

  let(:params) { { :api_key => @user.api_key } }

  it "creates a new asset" do
    post_json v1_user_assets_url(@user, params.merge(
      kind: 'wadus',
      filename: Rack::Test::UploadedFile.new(Rails.root.join('spec/support/data/cartofante_blue.png'), 'image/png').path)
    ) do |response|
      response.status.should be_success
      response.body[:public_url].should =~ /\/test\/test\/assets\/\d+cartofante_blue/
      response.body[:kind].should == 'wadus'
      @user.reload
      @user.assets.count.should == 1
      asset = @user.assets.first
      asset.public_url.should =~ /\/test\/test\/assets\/\d+cartofante_blue/
      asset.kind.should == 'wadus'
    end
  end

  it "returns some error message when the asset creation fails" do
    Asset.any_instance.stubs(:s3_bucket).raises("OMG AWS exception")
    post_json v1_user_assets_url(@user, params.merge(
      :filename => Rack::Test::UploadedFile.new(Rails.root.join('spec/support/data/cartofante_blue.png'), 'image/png').path)
    ) do |response|
      response.status.should == 400
      response.body[:description].should == "file error uploading OMG AWS exception"
    end
  end

  it "gets all assets" do
    3.times { FactoryGirl.create(:asset, user_id: @user.id) }

    get_json v1_user_assets_url(@user, params) do |response|
      response.status.should be_success
      response.body[:assets].size.should == 3
    end
  end

  it "deletes an asset" do
    FactoryGirl.create(:asset, user_id: @user.id)
    @user.reload
    delete_json v1_user_asset_url(@user, @user.assets.first, params) do |response|
      response.status.should be_success
      @user.reload
      @user.assets.count.should == 0
    end
  end
end
