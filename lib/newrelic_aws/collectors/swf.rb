module NewRelicAWS
  module Collectors
    class SWF < Base
      def domains 
        swf = AWS::SimpleWorkflow.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region,
        )
        swf.domains
      end


      def metric_list
        [
          ["DecisionTaskScheduleToStartTime", "Average","Milliseconds"],
          ["DecisionTaskStartToCloseTime", "Average", "Milliseconds"],
          ["DecisionTasksCompleted", "Sum", "Count"],
          ["StartedDecisionTasksTimedOutOnClose", "Sum", "Count"],
          ["WorkflowStartToCloseTime", "Average", "Milliseconds"],
          ["WorkflowsCanceled", "Sum", "Count"],
          ["WorkflowsCompleted", "Sum", "Count"],
          ["WorkflowsContinuedAsNew", "Sum", "Count"],
          ["WorkflowsFailed", "Sum", "Count"],
          ["WorkflowsTerminated", "Sum", "Count"],
          ["WorkflowsTimedOut", "Sum", "Count"],
        ]
      end

      def collect
        data_points = []
        domains.each do |domain|
            domain.workflow_types.each do |wf|
                metric_list.each do |(metric_name, statistic, unit)|
                    period = @period || 60
                    time_offset = 600 + @cloudwatch_delay
                    data_point = get_data_point(
                    :namespace   => "AWS/SWF",
                    :metric_name => metric_name,
                    :statistic   => statistic,
                    :unit        => unit,
                    :dimensions   => [
                        {
                            :name  => "Domain",
                            :value => domain.name
                        },
                        {
                            :name  => "WorkflowTypeName",
                            :value => wf.name 
                        },
                        {
                            :name  => "WorkflowTypeVersion",
                            :value => wf.version 
                        }
                    ],
                    :period => period,
                    :start_time => (Time.now.utc - (time_offset + period)).iso8601,
                    :end_time => (Time.now.utc - time_offset).iso8601
                    )
                    NewRelic::PlatformLogger.debug("metric_name: #{metric_name}, statistic: #{statistic}, unit: #{unit}, response: #{data_point.inspect}")
                    unless data_point.nil?
                        data_points << data_point
                    end
                end
            end
        end
        data_points
      end
    end
  end
end
