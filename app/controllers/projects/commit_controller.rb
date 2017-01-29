# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  include CreatesCommit
  include DiffForPath
  include DiffHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_read_pipeline!, only: [:pipelines]
  before_action :commit
  before_action :define_commit_vars, only: [:show, :diff_for_path, :pipelines]
  before_action :define_note_vars, only: [:show, :diff_for_path]
  before_action :authorize_edit_tree!, only: [:revert, :cherry_pick]

  def show
    apply_diff_view_cookie!

    respond_to do |format|
      format.html
      format.diff  { render text: @commit.to_diff }
      format.patch { render text: @commit.to_patch }
    end
  end

  def diff_for_path
    render_diff_for_path(@commit.diffs(diff_options))
  end

  def pipelines
    @pipelines = @commit.pipelines.order(id: :desc)

    respond_to do |format|
      format.html
      format.json do
        render json: PipelineSerializer
          .new(project: @project, user: @current_user)
          .with_pagination(request, response)
          .represent(@pipelines)
      end
    end
  end

  def branches
    @branches = @project.repository.branch_names_contains(commit.id)
    @tags = @project.repository.tag_names_contains(commit.id)
    render layout: false
  end

  def revert
    assign_change_commit_vars

    return render_404 if @target_branch.blank?

    create_commit(Commits::RevertService, success_notice: "The #{@commit.change_type_title(current_user)} has been successfully reverted.",
                                          success_path: successful_change_path, failure_path: failed_change_path)
  end

  def cherry_pick
    assign_change_commit_vars

    return render_404 if @target_branch.blank?

    create_commit(Commits::CherryPickService, success_notice: "The #{@commit.change_type_title(current_user)} has been successfully cherry-picked.",
                                              success_path: successful_change_path, failure_path: failed_change_path)
  end

  private

  def successful_change_path
    referenced_merge_request_url || namespace_project_commits_url(@project.namespace, @project, @target_branch)
  end

  def failed_change_path
    referenced_merge_request_url || namespace_project_commit_url(@project.namespace, @project, params[:id])
  end

  def referenced_merge_request_url
    if merge_request = @commit.merged_merge_request(current_user)
      namespace_project_merge_request_url(@project.namespace, @project, merge_request)
    end
  end

  def commit
    @noteable = @commit ||= @project.commit(params[:id])
  end

  def define_commit_vars
    return git_not_found! unless commit

    opts = diff_options
    opts[:ignore_whitespace_change] = true if params[:format] == 'diff'

    @diffs = commit.diffs(opts)
    @notes_count = commit.notes.count

    @environment = @project.latest_environment_for(@commit)
    @environment = nil unless can?(current_user, :read_environment, @environment)
  end

  def define_note_vars
    @grouped_diff_discussions = commit.notes.grouped_diff_discussions
    @notes = commit.notes.non_diff_notes.fresh

    Banzai::NoteRenderer.render(
      @grouped_diff_discussions.values.flat_map(&:notes) + @notes,
      @project,
      current_user,
    )

    @note = @project.build_commit_note(commit)

    @noteable = @commit
    @comments_target = {
      noteable_type: 'Commit',
      commit_id: @commit.id
    }
  end

  def assign_change_commit_vars
    @commit = project.commit(params[:id])
    @target_branch = params[:target_branch]
    @commit_params = {
      commit: @commit,
      create_merge_request: params[:create_merge_request].present? || different_project?
    }
  end
end
