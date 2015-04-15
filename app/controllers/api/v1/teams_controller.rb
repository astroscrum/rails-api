module Api
  class V1::TeamsController < ApplicationController

    skip_filter :authenticate!, only: [ :create ]

=begin
@api {get} /team Get your team
@apiHeader (Authorization) {String} X-Auth-Token Astroscrum auth token
@apiDescription This will return all the details about your team
@apiSuccess (Response) {String} id A uuid for this resource
@apiSuccess (Response) {String} slack_id The `slack_id` for this team (a uuid for slack)
@apiSuccess (Response) {String} name The team name in Slack
@apiSuccess (Response) {Integer} points The total point earnings for this team for the current season
@apiSuccessExample {json} Success-Response:
  HTTP/1.1 200 OK
  {
    "team": {
      "id": "ecb72023-12ae-4f98-8996-326df9b8b2c7",
      "name": "astroscrum",
      "points": 0,
      "slack_id": "U0485M91U"
    }
  }
@apiName GetTeam
@apiGroup Team
@apiParam {String} id String unique ID
=end
    def show
      puts current_team.to_json
      render json: current_team
    end

=begin
@api {post} /teams Create a team
@apiParam {String} name The team name in Slack
@apiParam {String} slack_id The `slack_id` of the team
@apiSuccessExample {json} Success-Response:
  HTTP/1.1 200 OK
  {
    "team": {
      "id": "ecb72023-12ae-4f98-8996-326df9b8b2c7",
      "name": "companyname",
      "points": 0,
      "slack_id": "U0485M91U"
    }
  }

@apiName CreateTeam
@apiGroup Team
=end
    def create
      @team = Team.new(team_params)

      if @team.save
        render json: @team
      else
        render json: { errors: @team.errors.messages }
      end
    end

    private

    def team_params
      params.require(:team).permit(:slack_id, :name)
    end

  end
end
