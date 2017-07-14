/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, no-var, comma-dangle, object-shorthand, one-var, one-var-declaration-per-line, no-else-return, quotes, max-len */
import Api from './api';

function ProjectSelect() {
  $('.js-projects-dropdown-toggle').each(function(i, dropdown) {
    var $dropdown;
    $dropdown = $(dropdown);
    return $dropdown.glDropdown({
      filterable: true,
      filterRemote: true,
      search: {
        fields: ['name_with_namespace']
      },
      data: function(term, callback) {
        var finalCallback, projectsCallback;
        var orderBy = $dropdown.data('order-by');
        finalCallback = function(projects) {
          return callback(projects);
        };
        if (this.includeGroups) {
          projectsCallback = function(projects) {
            var groupsCallback;
            groupsCallback = function(groups) {
              var data;
              data = groups.concat(projects);
              return finalCallback(data);
            };
            return Api.groups(term, {}, groupsCallback);
          };
        } else {
          projectsCallback = finalCallback;
        }
        if (this.groupId) {
          return Api.groupProjects(this.groupId, term, projectsCallback);
        } else {
          return Api.projects(term, { order_by: orderBy }, projectsCallback);
        }
      },
      url: function(project) {
        return project.web_url;
      },
      text: function(project) {
        return project.name_with_namespace;
      }
    });
  });
  $('.ajax-project-select').each(function(i, select) {
    var placeholder;
    this.groupId = $(select).data('group-id');
    this.includeGroups = $(select).data('include-groups');
    this.orderBy = $(select).data('order-by') || 'id';
    this.withIssuesEnabled = $(select).data('with-issues-enabled');
    this.withMergeRequestsEnabled = $(select).data('with-merge-requests-enabled');

    placeholder = "Search for project";
    if (this.includeGroups) {
      placeholder += " or group";
    }
    return $(select).select2({
      placeholder: placeholder,
      minimumInputLength: 0,
      query: (query) => {
        var finalCallback, projectsCallback;
        finalCallback = function(projects) {
          var data;
          data = {
            results: projects
          };
          return query.callback(data);
        };
        if (this.includeGroups) {
          projectsCallback = function(projects) {
            var groupsCallback;
            groupsCallback = function(groups) {
              var data;
              data = groups.concat(projects);
              return finalCallback(data);
            };
            return Api.groups(query.term, {}, groupsCallback);
          };
        } else {
          projectsCallback = finalCallback;
        }
        if (this.groupId) {
          return Api.groupProjects(this.groupId, query.term, projectsCallback);
        } else {
          return Api.projects(query.term, {
            order_by: this.orderBy,
            with_issues_enabled: this.withIssuesEnabled,
            with_merge_requests_enabled: this.withMergeRequestsEnabled
          }, projectsCallback);
        }
      },
      id: function(project) {
        return project.web_url;
      },
      text: function(project) {
        return project.name_with_namespace || project.name;
      },
      dropdownCssClass: "ajax-project-dropdown"
    });
  });
}

window.ProjectSelect = ProjectSelect;
