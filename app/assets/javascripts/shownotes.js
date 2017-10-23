/*jslint browser: true*/
/*global $*/

(function () {
    "use strict";

    function fuzzyMatch(pattern, text) {
        var pi = 0, ti = 0;
        while (pi < pattern.length && ti < text.length) {
            if (pattern.charAt(pi) === text.charAt(ti)) {
                pi += 1;
            }
            ti += 1;
        }
        if (pi === pattern.length) {
            return true;
        }
        return false;
    }

    function openDropDown() {
        if (!$("#top-input").hasClass("open")) {
            $(".topic-dropdown").dropdown("toggle");
        }
    }

    function TopicPopupView() {
        var self = this;
        // self.template = $('#topic-list-template').html();
        // self.selectedTemplate =
        //     $('#topic-selected-template').html();

        self.click_unpicked = function (event) {
            $(".selected-topics").append($(this).clone().addClass('right'));

            $(this).hide();
            $(this).addClass('picked');

          $('#topic-field').focus();
            event.stopPropagation();
        };

        self.click_picked = function (event) {
            var $clicked = $(this);
            $(".topic-suggestion").filter(function(){
              return $(this).text() == $clicked.text();
            }).show().removeClass('picked');
          $clicked.remove();

          event.stopPropagation();
        };

        self.selectedTopics = function () {
          var result = $(".topic-suggestions .picked").get().map(function (el) {
            return $(el).text()
          });
          return result;
        };

        self.bindTopicHandlers = function () {
            $(".topic-suggestions")
                .find(".topic-suggestion")
                .click(self.click_unpicked);
            $(".selected-topics").on('click', '.topic-suggestion', self.click_picked);
        };

        self.filterList = function () {
            var visibleCount = 0,
                string = $(this).val().toLowerCase();
            $(".topic-suggestions .topic-suggestion").each(
                function () {
                    var text = $(this).html().toLowerCase();
                    if (!$(this).hasClass('picked')) {
                        if (fuzzyMatch(string, text)) {
                            $(this).show();
                            visibleCount += 1;
                        } else {
                            $(this).hide();
                        }
                    }
                }
            );
            if (visibleCount === 0) {
                $("#no-topics-text").show();
            } else {
                $("#no-topics-text").hide();
            }
        };

        // register event handlers
        $("#topic-field").click(self.filterList);
        $("#topic-field").keyup(self.filterList);

        // invoke bindings for topic handlers
        self.bindTopicHandlers();
    }

    $(document).ready(function () {
        var page = 0,
            payload = {},
            loadComplete = false,
            topicPopupView = null;

        $.getJSON('/topics', function(topics) {
          $(".topic-suggestions").html(topics.map(function(topic) {
            return "<span class='topic-suggestion bg-primary'>"+topic+"</span>"
          }).join(''));
          topicPopupView = new TopicPopupView();
        });

        function handlePageResponse(page, pageCount) {
            $("#load-button").text("Load More");
            $("#search-button").text("Search");
            if (page === pageCount) {
                loadComplete = true;
                $("#load-button").hide();
            } else {
                $("#load-button").show();
            }
        }

        function startSearch() {
            page = 1;
            loadComplete = false;
            $("#search-button").text("Searching...");
        }

        function startLoadingNotes() {
            $("#load-button").show();
            $("#load-button").text("Loading...");
        }

        function nextPage() {
            if (loadComplete) {
                return false;
            }
            startLoadingNotes();
            page += 1;
            payload.page = page;
            $.post('search', payload,
                function (response) {
                  $("#content").append(formatResults(response));
                    handlePageResponse(response.page,
                        response.page_count);
                });
        }

        function formatResults(response) {
          return "<ul class='list-unstyled'>" +
          response.results.map(function(result) {
            return "<li class='note'>" +
                "<div class='row'>" +
                  "<div class='col-1'>" +
                    "<a href='http://"+result.show_id+".nashownotes.com' class='show-link'>["+ result.show_id + "]</a>" +
                    "<a href='http://www.noagendaplayer.com/listen/" + result.show_id + "' class='link-icon' title='Listen to show " + result.show_id + " at noagendaplayer.com'>" +
                      "<img class='headphones' src='/assets/images/glyphicons-77-headphones.png'>" +
                    "</a>" +
                  "</div>" +
                  "<div class='col-11 col-md-9 text-right d-md-none'>" +
                  "<span>"+result.topic+"</span>" +
                  "</div>" +
                  "<div class='col-12 col-md-9 shownote-title-div shownote-heading pointer bg-info'>" +
                    "<span class='title'>"+result.title+"</span>" +
                  "</div>" +
                  "<div class='col-2 text-right d-none d-md-block hidden-sm-down'>" +
                    "<span>"+result.topic+"</span>" +
                  "</div>" +
                "</div>" +
              "</li>" +
              "<div class='bg-grey shownote-entries' style='display: none'>" +
                result.text.split("\n").map(function(line) { return "<p>" + line + "</p>" }).join('') +
              "</div>"
          }).join('');
        }

        function search() {
            startSearch();
            startLoadingNotes();
            payload = {"string": $("#search-field").val(),
                "topics": topicPopupView.selectedTopics(),
                "page": page,
                "min_show": $("#show-from").val(),
                "max_show": $("#show-to").val()};

            $("#content").html("")
          $.post('search', payload,
                function (response) {
                  var initial = "<div><p>Found " + response.count + " matches</p></div>";
                  $("#content").html(initial + formatResults(response));
                  handlePageResponse(response.page, response.page_count);
                });
        }

        $("#content").on("click", ".shownote-title-div",
            function () {
                $(this).parent().parent().next().toggle(200);
            });

        $("#content").on("click", ".click-close",
            function () {
                $(this).parent().parent().parent().toggle(200);
            });

        $("#content").on("mouseenter", ".shownote-heading",
            function () {
                $(this).removeClass("bg-info");
                $(this).addClass("bg-primary");
            });

        $("#content").on("mouseleave", ".shownote-heading",
            function () {
                $(this).removeClass("bg-primary");
                $(this).addClass("bg-info");
            });

        $("#search-button").click(search);

        $("#topic-field").click(function (e) {
            e.stopPropagation();
            openDropDown();
        });

        $("#topic-field").focusin(function (e) {
            e.stopPropagation();
            openDropDown();
        });

        $("input").keypress(function (e) {
            if (e.which === 13) {
              $('.topic-dropdown').removeClass('show');
              search();
            }
        });

        $("#load-button").click(function () {
            nextPage();
        });

        $(window).scroll(function () {
            if ($(window).scrollTop() ===
                    $(document).height() - $(window).height() && page > 0) {
                nextPage();
            }
        });

        $(window).click(function(){
          $('.topic-dropdown').removeClass('show');
        })
    });
}());

