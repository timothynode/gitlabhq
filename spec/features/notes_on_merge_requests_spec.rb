require 'spec_helper'

describe 'Comments' do
  include RepoHelpers

  describe "On a merge request", js: true, feature: true do
    let!(:merge_request) { create(:merge_request) }
    let!(:project) { merge_request.source_project }
    let!(:note) { create(:note_on_merge_request, :with_attachment, project: project) }

    before do
      login_as :admin
      visit project_merge_request_path(project, merge_request)
    end

    subject { page }

    describe "the note form" do
      it 'should be valid' do
        should have_css(".js-main-target-form", visible: true, count: 1)
        find(".js-main-target-form input[type=submit]").value.should == "Add Comment"
        within(".js-main-target-form") { should_not have_link("Cancel") }
        within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: false) }
      end

      describe "with text" do
        before do
          within(".js-main-target-form") do
            fill_in "note[note]", with: "This is awesome"
          end
        end

        it 'should have enable submit button and preview button' do
          within(".js-main-target-form") { should_not have_css(".js-comment-button[disabled]") }
          within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: true) }
        end
      end
    end

    describe "when posting a note" do
      before do
        within(".js-main-target-form") do
          fill_in "note[note]", with: "This is awsome!"
          find(".js-note-preview-button").trigger("click")
          click_button "Add Comment"
        end
      end

      it 'should be added and form reset' do
        should have_content("This is awsome!")
        within(".js-main-target-form") { should have_no_field("note[note]", with: "This is awesome!") }
        within(".js-main-target-form") { should have_css(".js-note-preview", visible: false) }
        within(".js-main-target-form") { should have_css(".js-note-text", visible: true) }
      end
    end

    describe "when editing a note", js: true do
      it "should contain the hidden edit form" do
        within("#note_#{note.id}") { should have_css(".note-edit-form", visible: false) }
      end

      describe "editing the note" do
        before do
          find('.note').hover
          find(".js-note-edit").click
        end

        it "should show the note edit form and hide the note body" do
          within("#note_#{note.id}") do
            find(".note-edit-form", visible: true).should be_visible
            find(".note-text", visible: false).should_not be_visible
          end
        end

        it "should reset the edit note form textarea with the original content of the note if cancelled" do
          find('.note').hover
          find(".js-note-edit").click

          within(".note-edit-form") do
            fill_in "note[note]", with: "Some new content"
            find(".btn-cancel").click
            find(".js-note-text", visible: false).text.should == note.note
          end
        end

        it "appends the edited at time to the note" do
          find('.note').hover
          find(".js-note-edit").click

          within(".note-edit-form") do
            fill_in "note[note]", with: "Some new content"
            find(".btn-save").click
          end

          within("#note_#{note.id}") do
            should have_css(".note-last-update small")
            find(".note-last-update small").text.should match(/Edited less than a minute ago/)
          end
        end
      end

      describe "deleting an attachment" do
        before do
          find('.note').hover
          find(".js-note-edit").click
        end

        it "shows the delete link" do
          within(".note-attachment") do
            should have_css(".js-note-attachment-delete")
          end
        end

        it "removes the attachment div and resets the edit form" do
          find(".js-note-attachment-delete").click
          should_not have_css(".note-attachment")
          find(".note-edit-form", visible: false).should_not be_visible
        end
      end
    end
  end

  describe "On a merge request diff", js: true, feature: true do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.source_project }

    before do
      login_as :admin
      visit diffs_project_merge_request_path(project, merge_request)
    end

    subject { page }

    describe "when adding a note" do
      before do
        click_diff_line
      end

      describe "the notes holder" do
        it { should have_css(".js-temp-notes-holder") }

        it { within(".js-temp-notes-holder") { should have_css(".new_note") } }
      end

      describe "the note form" do
        it "shouldn't add a second form for same row" do
          click_diff_line

          should have_css("tr[id='#{line_code}'] + .js-temp-notes-holder form", count: 1)
        end

        it "should be removed when canceled" do
          within(".diff-file form[rel$='#{line_code}']") do
            find(".js-close-discussion-note-form").trigger("click")
          end

          should have_no_css(".js-temp-notes-holder")
        end
      end
    end

    describe "with muliple note forms" do
      before do
        click_diff_line
        click_diff_line(line_code_2)
      end

      it { should have_css(".js-temp-notes-holder", count: 2) }

      describe "previewing them separately" do
        before do
          # add two separate texts and trigger previews on both
          within("tr[id='#{line_code}'] + .js-temp-notes-holder") do
            fill_in "note[note]", with: "One comment on line 7"
            find(".js-note-preview-button").trigger("click")
          end
          within("tr[id='#{line_code_2}'] + .js-temp-notes-holder") do
            fill_in "note[note]", with: "Another comment on line 10"
            find(".js-note-preview-button").trigger("click")
          end
        end
      end

      describe "posting a note" do
        before do
          within("tr[id='#{line_code_2}'] + .js-temp-notes-holder") do
            fill_in "note[note]", with: "Another comment on line 10"
            click_button("Add Comment")
          end
        end

        it 'should be added as discussion' do
          should have_content("Another comment on line 10")
          should have_css(".notes_holder")
          should have_css(".notes_holder .note", count: 1)
          should have_button('Reply')
        end
      end
    end
  end

  def line_code
    sample_compare.changes.first[:line_code]
  end

  def line_code_2
    sample_compare.changes.last[:line_code]
  end

  def click_diff_line(data = nil)
    data ||= line_code
    find("button[data-line-code=\"#{data}\"]").click
  end
end
