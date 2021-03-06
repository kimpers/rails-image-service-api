require 'rails_helper'
require 'base64'

RSpec.describe PostsController, type: :request do
  before :each do
    @tag = FactoryGirl.create(:tag)
    encoded_image = "data:image/png;base64," << Base64.encode64(File.open(Rails.root + 'spec/fixtures/images/ruby.png', 'rb').read)
    @post = {
      image: encoded_image,
      description: 'hello',
      tags: [@tag.text],
      user_tags: [@user.username]
    }
  end

  describe 'find post' do
    before :each do
      @post = FactoryGirl.create(:post)
    end

    it 'should find post with valid id' do
      get "/post/#{@post.id}"
      expect(response.status).to be 200
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be true
      expect(response_json['result']['id']).to eq(@post.id)
    end

    it 'should return 404 with an invalid id' do
      get "/post/#{@post.id + 100}"
      expect(response.status).to be 404
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be false
    end
  end

  describe 'create post' do
    it 'should successfully create post with all params' do
      post '/post/create', @post, authorization: @token
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be true
      expect(response.status).to be 201
      expect(Tag.find_by(text: @tag.text)).to eq(@tag)
      expect(Post.all.size).to be 1
      expect(Post.all.first.tagged_users.first).to eq(@user)
    end

    it "should create new tags if they don't exist" do
      @post[:tags] = ["tag1", "tag2"]
      post '/post/create', @post, authorization: @token
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be true
      expect(response.status).to be 201
      expect(Tag.all.size).to be 3
    end

    it 'should ignore fake usernames' do
      @post[:user_tags] << "fake_user"
      post '/post/create', @post, authorization: @token
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be true
      expect(response.status).to be 201
      expect(Post.all.first.tagged_users.size).to be 1
      expect(Post.all.first.tagged_users.first).to eq(@user)
    end

    it 'should fail without an image' do
      @post[:image] = nil
      post '/post/create', @post, authorization: @token
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be false
      expect(response.status).to be 500
    end

    it 'should set logged in user as poster' do
      post '/post/create', @post, authorization: @token
      response_json = JSON.parse(response.body)
      expect(response_json['success']).to be true
      expect(Post.last.author).to eq @user
    end
  end

  describe 'update post' do
    before :each do
      @post = FactoryGirl.build(:post)
      expect(@post.create_assoc_and_save(@tag, @user)).to_not be false
    end
    it 'should update description correctly' do
      changes = {description: 'updated'}
      patch "/post/#{@post.id}/update", changes, authorization: @token
      expect(response.status).to be 200
      expect(Post.find(@post.id).description).to eq changes[:description]
    end

    it 'should update tags correctly' do
      tag1 = FactoryGirl.create(:tag)
      tag2 = FactoryGirl.build(:tag)
      changes = {tags: [tag1.text, tag2.text]}
      patch "/post/#{@post.id}/update", changes, authorization: @token
      expect(response.status).to be 200
      found_post = Post.find(@post.id)
      expect(found_post.tags.size).to be 2
      expect(found_post.tags.include?(tag1)).to be true
      tag2 = Tag.find_by(text: tag2.text)
      expect(found_post.tags.include?(tag2)).to be true
    end

    it 'should update tagged users' do
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      changes = {user_tags: [user1.username, user2.username]}
      patch "/post/#{@post.id}/update", changes, authorization: @token
      expect(response.status).to be 200
      found_post = Post.find(@post.id)
      expect(found_post.tagged_users.size).to be 2
      expect(found_post.tagged_users.include?(user1)).to be true
      expect(found_post.tagged_users.include?(user2)).to be true
    end

    it 'should ignore none existing users' do
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.build(:user)
      changes = {user_tags: [user1.username, user2.username]}
      patch "/post/#{@post.id}/update", changes, authorization: @token
      expect(response.status).to be 200
      found_post = Post.find(@post.id)
      expect(found_post.tagged_users.size).to be 1
      expect(found_post.tagged_users.include?(user1)).to be true
      expect(found_post.tagged_users.include?(user2)).to be false
    end
  end
end
