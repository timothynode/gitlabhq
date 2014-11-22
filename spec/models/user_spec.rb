# == Schema Information
#
# Table name: users
#
#  id                       :integer          not null, primary key
#  email                    :string(255)      default(""), not null
#  encrypted_password       :string(255)      default(""), not null
#  reset_password_token     :string(255)
#  reset_password_sent_at   :datetime
#  remember_created_at      :datetime
#  sign_in_count            :integer          default(0)
#  current_sign_in_at       :datetime
#  last_sign_in_at          :datetime
#  current_sign_in_ip       :string(255)
#  last_sign_in_ip          :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  name                     :string(255)
#  admin                    :boolean          default(FALSE), not null
#  projects_limit           :integer          default(10)
#  skype                    :string(255)      default(""), not null
#  linkedin                 :string(255)      default(""), not null
#  twitter                  :string(255)      default(""), not null
#  authentication_token     :string(255)
#  theme_id                 :integer          default(1), not null
#  bio                      :string(255)
#  failed_attempts          :integer          default(0)
#  locked_at                :datetime
#  extern_uid               :string(255)
#  provider                 :string(255)
#  username                 :string(255)
#  can_create_group         :boolean          default(TRUE), not null
#  can_create_team          :boolean          default(TRUE), not null
#  state                    :string(255)
#  color_scheme_id          :integer          default(1), not null
#  notification_level       :integer          default(1), not null
#  password_expires_at      :datetime
#  created_by_id            :integer
#  last_credential_check_at :datetime
#  avatar                   :string(255)
#  confirmation_token       :string(255)
#  confirmed_at             :datetime
#  confirmation_sent_at     :datetime
#  unconfirmed_email        :string(255)
#  hide_no_ssh_key          :boolean          default(FALSE)
#  website_url              :string(255)      default(""), not null
#

require 'spec_helper'

describe User do
  describe "Associations" do
    it { should have_one(:namespace) }
    it { should have_many(:snippets).class_name('Snippet').dependent(:destroy) }
    it { should have_many(:project_members).dependent(:destroy) }
    it { should have_many(:groups) }
    it { should have_many(:keys).dependent(:destroy) }
    it { should have_many(:events).class_name('Event').dependent(:destroy) }
    it { should have_many(:recent_events).class_name('Event') }
    it { should have_many(:issues).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_many(:assigned_issues).dependent(:destroy) }
    it { should have_many(:merge_requests).dependent(:destroy) }
    it { should have_many(:assigned_merge_requests).dependent(:destroy) }
  end

  describe "Mass assignment" do
  end

  describe 'validations' do
    it { should validate_presence_of(:username) }
    it { should validate_presence_of(:projects_limit) }
    it { should validate_numericality_of(:projects_limit) }
    it { should allow_value(0).for(:projects_limit) }
    it { should_not allow_value(-1).for(:projects_limit) }

    it { should ensure_length_of(:bio).is_within(0..255) }

    describe 'email' do
      it 'accepts info@example.com' do
        user = build(:user, email: 'info@example.com')
        expect(user).to be_valid
      end

      it 'accepts info+test@example.com' do
        user = build(:user, email: 'info+test@example.com')
        expect(user).to be_valid
      end

      it "accepts o'reilly@example.com" do
        user = build(:user, email: "o'reilly@example.com")
        expect(user).to be_valid
      end

      it 'rejects test@test@example.com' do
        user = build(:user, email: 'test@test@example.com')
        expect(user).to be_invalid
      end

      it 'rejects mailto:test@example.com' do
        user = build(:user, email: 'mailto:test@example.com')
        expect(user).to be_invalid
      end

      it "rejects lol!'+=?><#$%^&*()@gmail.com" do
        user = build(:user, email: "lol!'+=?><#$%^&*()@gmail.com")
        expect(user).to be_invalid
      end
    end
  end

  describe "Respond to" do
    it { should respond_to(:is_admin?) }
    it { should respond_to(:name) }
    it { should respond_to(:private_token) }
  end

  describe '#generate_password' do
    it "should execute callback when force_random_password specified" do
      user = build(:user, force_random_password: true)
      user.should_receive(:generate_password)
      user.save
    end

    it "should not generate password by default" do
      user = create(:user, password: 'abcdefghe')
      user.password.should == 'abcdefghe'
    end

    it "should generate password when forcing random password" do
      Devise.stub(:friendly_token).and_return('123456789')
      user = create(:user, password: 'abcdefg', force_random_password: true)
      user.password.should == '12345678'
    end
  end

  describe 'authentication token' do
    it "should have authentication token" do
      user = create(:user)
      user.authentication_token.should_not be_blank
    end
  end

  describe 'projects' do
    before do
      @user = create :user
      @project = create :project, namespace: @user.namespace
      @project_2 = create :project, group: create(:group) # Grant MASTER access to the user
      @project_3 = create :project, group: create(:group) # Grant DEVELOPER access to the user

      @project_2.team << [@user, :master]
      @project_3.team << [@user, :developer]
    end

    it { @user.authorized_projects.should include(@project) }
    it { @user.authorized_projects.should include(@project_2) }
    it { @user.authorized_projects.should include(@project_3) }
    it { @user.owned_projects.should include(@project) }
    it { @user.owned_projects.should_not include(@project_2) }
    it { @user.owned_projects.should_not include(@project_3) }
    it { @user.personal_projects.should include(@project) }
    it { @user.personal_projects.should_not include(@project_2) }
    it { @user.personal_projects.should_not include(@project_3) }
  end

  describe 'groups' do
    before do
      @user = create :user
      @group = create :group
      @group.add_owner(@user)
    end

    it { @user.several_namespaces?.should be_true }
    it { @user.authorized_groups.should == [@group] }
    it { @user.owned_groups.should == [@group] }
  end

  describe 'group multiple owners' do
    before do
      @user = create :user
      @user2 = create :user
      @group = create :group
      @group.add_owner(@user)

      @group.add_user(@user2, GroupMember::OWNER)
    end

    it { @user2.several_namespaces?.should be_true }
  end

  describe 'namespaced' do
    before do
      @user = create :user
      @project = create :project, namespace: @user.namespace
    end

    it { @user.several_namespaces?.should be_false }
  end

  describe 'blocking user' do
    let(:user) { create(:user, name: 'John Smith') }

    it "should block user" do
      user.block
      user.blocked?.should be_true
    end
  end

  describe 'filter' do
    before do
      User.delete_all
      @user = create :user
      @admin = create :user, admin: true
      @blocked = create :user, state: :blocked
    end

    it { User.filter("admins").should == [@admin] }
    it { User.filter("blocked").should == [@blocked] }
    it { User.filter("wop").should include(@user, @admin, @blocked) }
    it { User.filter(nil).should include(@user, @admin) }
  end

  describe :not_in_project do
    before do
      User.delete_all
      @user = create :user
      @project = create :project
    end

    it { User.not_in_project(@project).should include(@user, @project.owner) }
  end

  describe 'user creation' do
    describe 'normal user' do
      let(:user) { create(:user, name: 'John Smith') }

      it { user.is_admin?.should be_false }
      it { user.require_ssh_key?.should be_true }
      it { user.can_create_group?.should be_true }
      it { user.can_create_project?.should be_true }
      it { user.first_name.should == 'John' }
    end

    describe 'with defaults' do
      let(:user) { User.new }

      it "should apply defaults to user" do
        user.projects_limit.should == Gitlab.config.gitlab.default_projects_limit
        user.can_create_group.should == Gitlab.config.gitlab.default_can_create_group
        user.theme_id.should == Gitlab.config.gitlab.default_theme
      end
    end

    describe 'with default overrides' do
      let(:user) { User.new(projects_limit: 123, can_create_group: false, can_create_team: true, theme_id: Gitlab::Theme::BASIC) }

      it "should apply defaults to user" do
        user.projects_limit.should == 123
        user.can_create_group.should be_false
        user.theme_id.should == Gitlab::Theme::BASIC
      end
    end
  end

  describe 'search' do
    let(:user1) { create(:user, username: 'James', email: 'james@testing.com') }
    let(:user2) { create(:user, username: 'jameson', email: 'jameson@example.com') }

    it "should be case insensitive" do
      User.search(user1.username.upcase).to_a.should == [user1]
      User.search(user1.username.downcase).to_a.should == [user1]
      User.search(user2.username.upcase).to_a.should == [user2]
      User.search(user2.username.downcase).to_a.should == [user2]
      User.search(user1.username.downcase).to_a.count.should == 2
      User.search(user2.username.downcase).to_a.count.should == 1
    end
  end

  describe 'by_username_or_id' do
    let(:user1) { create(:user, username: 'foo') }

    it "should get the correct user" do
      User.by_username_or_id(user1.id).should == user1
      User.by_username_or_id('foo').should == user1
      User.by_username_or_id(-1).should be_nil
      User.by_username_or_id('bar').should be_nil
    end
  end

  describe '.by_login' do
    let(:username) { 'John' }
    let!(:user) { create(:user, username: username) }

    it 'should get the correct user' do
      expect(User.by_login(user.email.upcase)).to eq user
      expect(User.by_login(user.email)).to eq user
      expect(User.by_login(username.downcase)).to eq user
      expect(User.by_login(username)).to eq user
      expect(User.by_login(nil)).to be_nil
      expect(User.by_login('')).to be_nil
    end
  end

  describe 'all_ssh_keys' do
    it { should have_many(:keys).dependent(:destroy) }

    it "should have all ssh keys" do
      user = create :user
      key = create :key, key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD33bWLBxu48Sev9Fert1yzEO4WGcWglWF7K/AwblIUFselOt/QdOL9DSjpQGxLagO1s9wl53STIO8qGS4Ms0EJZyIXOEFMjFJ5xmjSy+S37By4sG7SsltQEHMxtbtFOaW5LV2wCrX+rUsRNqLMamZjgjcPO0/EgGCXIGMAYW4O7cwGZdXWYIhQ1Vwy+CsVMDdPkPgBXqK7nR/ey8KMs8ho5fMNgB5hBw/AL9fNGhRw3QTD6Q12Nkhl4VZES2EsZqlpNnJttnPdp847DUsT6yuLRlfiQfz5Cn9ysHFdXObMN5VYIiPFwHeYCZp1X2S4fDZooRE8uOLTfxWHPXwrhqSH", user_id: user.id

      user.all_ssh_keys.should include(key.key)
    end
  end

  describe :avatar_type do
    let(:user) { create(:user) }

    it "should be true if avatar is image" do
      user.update_attribute(:avatar, 'uploads/avatar.png')
      user.avatar_type.should be_true
    end

    it "should be false if avatar is html page" do
      user.update_attribute(:avatar, 'uploads/avatar.html')
      user.avatar_type.should == ["only images allowed"]
    end
  end

  describe :requires_ldap_check? do
    let(:user) { User.new }

    it 'is false when LDAP is disabled' do
      # Create a condition which would otherwise cause 'true' to be returned
      user.stub(ldap_user?: true)
      user.last_credential_check_at = nil
      expect(user.requires_ldap_check?).to be_false
    end

    context 'when LDAP is enabled' do
      before { Gitlab.config.ldap.stub(enabled: true) }

      it 'is false for non-LDAP users' do
        user.stub(ldap_user?: false)
        expect(user.requires_ldap_check?).to be_false
      end

      context 'and when the user is an LDAP user' do
        before { user.stub(ldap_user?: true) }

        it 'is true when the user has never had an LDAP check before' do
          user.last_credential_check_at = nil
          expect(user.requires_ldap_check?).to be_true
        end

        it 'is true when the last LDAP check happened over 1 hour ago' do
          user.last_credential_check_at = 2.hours.ago
          expect(user.requires_ldap_check?).to be_true
        end
      end
    end
  end

  describe :ldap_user? do
    let(:user) { build(:user, :ldap) }

    it "is true if provider name starts with ldap" do
      user.provider = 'ldapmain'
      expect( user.ldap_user? ).to be_true
    end

    it "is false for other providers" do
      user.provider = 'other-provider'
      expect( user.ldap_user? ).to be_false
    end

    it "is false if no extern_uid is provided" do
      user.extern_uid = nil
      expect( user.ldap_user? ).to be_false
    end
  end

  describe '#full_website_url' do
    let(:user) { create(:user) }

    it 'begins with http if website url omits it' do
      user.website_url = 'test.com'

      expect(user.full_website_url).to eq 'http://test.com'
    end

    it 'begins with http if website url begins with http' do
      user.website_url = 'http://test.com'

      expect(user.full_website_url).to eq 'http://test.com'
    end

    it 'begins with https if website url begins with https' do
      user.website_url = 'https://test.com'

      expect(user.full_website_url).to eq 'https://test.com'
    end
  end

  describe '#short_website_url' do
    let(:user) { create(:user) }

    it 'does not begin with http if website url omits it' do
      user.website_url = 'test.com'

      expect(user.short_website_url).to eq 'test.com'
    end

    it 'does not begin with http if website url begins with http' do
      user.website_url = 'http://test.com'

      expect(user.short_website_url).to eq 'test.com'
    end

    it 'does not begin with https if website url begins with https' do
      user.website_url = 'https://test.com'

      expect(user.short_website_url).to eq 'test.com'
    end
  end

  describe "#starred?" do
    it "determines if user starred a project" do
      user = create :user
      project1 = create :project, :public
      project2 = create :project, :public

      expect(user.starred?(project1)).to be_false
      expect(user.starred?(project2)).to be_false

      star1 = UsersStarProject.create!(project: project1, user: user)
      expect(user.starred?(project1)).to be_true
      expect(user.starred?(project2)).to be_false

      star2 = UsersStarProject.create!(project: project2, user: user)
      expect(user.starred?(project1)).to be_true
      expect(user.starred?(project2)).to be_true

      star1.destroy
      expect(user.starred?(project1)).to be_false
      expect(user.starred?(project2)).to be_true

      star2.destroy
      expect(user.starred?(project1)).to be_false
      expect(user.starred?(project2)).to be_false
    end
  end

  describe "#toggle_star" do
    it "toggles stars" do
      user = create :user
      project = create :project, :public

      expect(user.starred?(project)).to be_false
      user.toggle_star(project)
      expect(user.starred?(project)).to be_true
      user.toggle_star(project)
      expect(user.starred?(project)).to be_false
    end
  end

  describe "#sort" do
    before do
      User.delete_all
      @user = create :user, created_at: Date.today, last_sign_in_at: Date.today, name: 'Alpha'
      @user1 = create :user, created_at: Date.today - 1, last_sign_in_at: Date.today - 1, name: 'Omega'
    end
    
    it "sorts users as recently_signed_in" do
      User.sort('recent_sign_in').first.should == @user
    end

    it "sorts users as late_signed_in" do
      User.sort('oldest_sign_in').first.should == @user1
    end

    it "sorts users as recently_created" do
      User.sort('recently_created').first.should == @user
    end

    it "sorts users as late_created" do
      User.sort('late_created').first.should == @user1
    end

    it "sorts users by name when nil is passed" do
      User.sort(nil).first.should == @user
    end
  end
end
