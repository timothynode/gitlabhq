require 'spec_helper'

describe Projects::TreeController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]

    project.stub(:branches).and_return(['master', 'foo/bar/baz'])
    project.stub(:tags).and_return(['v1.0.0', 'v2.0.0'])
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    # Make sure any errors accessing the tree in our views bubble up to this spec
    render_views

    before { get :show, project_id: project.to_param, id: id }

    context "valid branch, no path" do
      let(:id) { 'master' }
      it { should respond_with(:success) }
    end

    context "valid branch, valid path" do
      let(:id) { 'master/encoding/' }
      it { should respond_with(:success) }
    end

    context "valid branch, invalid path" do
      let(:id) { 'master/invalid-path/' }
      it { should respond_with(:not_found) }
    end

    context "invalid branch, valid path" do
      let(:id) { 'invalid-branch/encoding/' }
      it { should respond_with(:not_found) }
    end
  end

  describe 'GET show with blob path' do
    render_views

    before do
      get :show, project_id: project.to_param, id: id
    end

    context 'redirect to blob' do
      let(:id) { 'master/README.md' }
      it { should redirect_to("/#{project.path_with_namespace}/blob/master/README.md") }
    end
  end
end
