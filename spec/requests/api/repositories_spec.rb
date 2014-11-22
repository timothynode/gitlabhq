require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  include RepoHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:guest) { create(:project_member, user: user2, project: project, access_level: ProjectMember::GUEST) }

  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get api("/projects/#{project.id}/repository/tags", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.tags.sort_by(&:name).reverse.first.name
    end
  end

  describe 'POST /projects/:id/repository/tags' do
    context 'lightweight tags' do
      it 'should create a new tag' do
        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.0.1',
             ref: 'master'

        response.status.should == 201
        json_response['name'].should == 'v7.0.1'
      end
    end

    context 'annotated tag' do
      it 'should create a new annotated tag' do
        # Identity must be set in .gitconfig to create annotated tag.
        repo_path = project.repository.path_to_repo
        system(*%W(git --git-dir=#{repo_path} config user.name #{user.name}))
        system(*%W(git --git-dir=#{repo_path} config user.email #{user.email}))

        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.1.0',
             ref: 'master',
             message: 'Release 7.1.0'

        response.status.should == 201
        json_response['name'].should == 'v7.1.0'
        json_response['message'].should == 'Release 7.1.0'
      end
    end

    it 'should deny for user without push access' do
      post api("/projects/#{project.id}/repository/tags", user2),
           tag_name: 'v1.9.0',
           ref: '621491c677087aa243f165eab467bfdfbee00be1'
      response.status.should == 403
    end

    it 'should return 400 if tag name is invalid' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v 1.0.0',
           ref: 'master'
      response.status.should == 400
      json_response['message'].should == 'Tag name invalid'
    end

    it 'should return 400 if tag already exists' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v8.0.0',
           ref: 'master'
      response.status.should == 201
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v8.0.0',
           ref: 'master'
      response.status.should == 400
      json_response['message'].should == 'Tag already exists'
    end

    it 'should return 400 if ref name is invalid' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'mytag',
           ref: 'foo'
      response.status.should == 400
      json_response['message'].should == 'Invalid reference name'
    end
  end

  describe "GET /projects/:id/repository/tree" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/tree", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.first['name'].should == 'encoding'
        json_response.first['type'].should == 'tree'
        json_response.first['mode'].should == '040000'
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/tree")
        response.status.should == 401
      end
    end
  end

  describe "GET /projects/:id/repository/blobs/:sha" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/blobs/master?filepath=README.md", user)
      response.status.should == 200
    end

    it "should return 404 for invalid branch_name" do
      get api("/projects/#{project.id}/repository/blobs/invalid_branch_name?filepath=README.md", user)
      response.status.should == 404
    end

    it "should return 404 for invalid file" do
      get api("/projects/#{project.id}/repository/blobs/master?filepath=README.invalid", user)
      response.status.should == 404
    end

    it "should return a 400 error if filepath is missing" do
      get api("/projects/#{project.id}/repository/blobs/master", user)
      response.status.should == 400
    end
  end

  describe "GET /projects/:id/repository/commits/:sha/blob" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/commits/master/blob?filepath=README.md", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/repository/raw_blobs/:sha" do
    it "should get the raw file contents" do
      get api("/projects/#{project.id}/repository/raw_blobs/#{sample_blob.oid}", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    it "should get the archive" do
      get api("/projects/#{project.id}/repository/archive", user)
      repo_name = project.repository.name.gsub("\.git", "")
      response.status.should == 200
      response.headers['Content-Disposition'].should =~ /filename\=\"#{repo_name}\-[^\.]+\.tar.gz\"/
      response.content_type.should == MIME::Types.type_for('file.tar.gz').first.content_type
    end

    it "should get the archive.zip" do
      get api("/projects/#{project.id}/repository/archive.zip", user)
      repo_name = project.repository.name.gsub("\.git", "")
      response.status.should == 200
      response.headers['Content-Disposition'].should =~ /filename\=\"#{repo_name}\-[^\.]+\.zip\"/
      response.content_type.should == MIME::Types.type_for('file.zip').first.content_type
    end

    it "should get the archive.tar.bz2" do
      get api("/projects/#{project.id}/repository/archive.tar.bz2", user)
      repo_name = project.repository.name.gsub("\.git", "")
      response.status.should == 200
      response.headers['Content-Disposition'].should =~ /filename\=\"#{repo_name}\-[^\.]+\.tar.bz2\"/
      response.content_type.should == MIME::Types.type_for('file.tar.bz2').first.content_type
    end

    it "should return 404 for invalid sha" do
      get api("/projects/#{project.id}/repository/archive/?sha=xxx", user)
      response.status.should == 404
    end
  end

  describe 'GET /projects/:id/repository/compare' do
    it "should compare branches" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'feature'
      response.status.should == 200
      json_response['commits'].should be_present
      json_response['diffs'].should be_present
    end

    it "should compare tags" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'v1.0.0', to: 'v1.1.0'
      response.status.should == 200
      json_response['commits'].should be_present
      json_response['diffs'].should be_present
    end

    it "should compare commits" do
      get api("/projects/#{project.id}/repository/compare", user), from: sample_commit.id, to: sample_commit.parent_id
      response.status.should == 200
      json_response['commits'].should be_empty
      json_response['diffs'].should be_empty
      json_response['compare_same_ref'].should be_false
    end

    it "should compare commits in reverse order" do
      get api("/projects/#{project.id}/repository/compare", user), from: sample_commit.parent_id, to: sample_commit.id
      response.status.should == 200
      json_response['commits'].should be_present
      json_response['diffs'].should be_present
    end

    it "should compare same refs" do
      get api("/projects/#{project.id}/repository/compare", user), from: 'master', to: 'master'
      response.status.should == 200
      json_response['commits'].should be_empty
      json_response['diffs'].should be_empty
      json_response['compare_same_ref'].should be_true
    end
  end

  describe 'GET /projects/:id/repository/contributors' do
    it 'should return valid data' do
      get api("/projects/#{project.id}/repository/contributors", user)
      response.status.should == 200
      json_response.should be_an Array
      contributor = json_response.first
      contributor['email'].should == 'dmitriy.zaporozhets@gmail.com'
      contributor['name'].should == 'Dmitriy Zaporozhets'
      contributor['commits'].should == 13
      contributor['additions'].should == 0
      contributor['deletions'].should == 0
    end
  end
end
