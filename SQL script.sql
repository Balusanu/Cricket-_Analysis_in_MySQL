/*Retreiving data from all the tables*/

use wpl_2023;
select * from batting_summary;
select * from bowling_summary;
select * from match_summary;
select * from player_info;

/*understanding the tournment*/

/*Teams Participated in the tournament*/
select distinct winner from match_summary;
/*Grounds Used for the tournament*/
select distinct ground from match_summary;
/*Total number of matches played in the tournament*/
select count(matchID) from match_summary;
/*Total number of Players played in the tournament*/
select count(name) from player_info;

/*Analysing the Tournament Matches*/

/*Number of matches won by each team*/
select winner,
count(winner) as Number_of_Matches_won
from match_summary
group by winner;
/*Number of matches Played in each ground*/
select ground,
count(matchID) as Number_of_Matches_played
from match_summary
group by ground;
/*Total runs Scored and wickets taken in each ground*/
select ground,
sum(bts.runs) as Total_runs,
sum(wickets) as Total_wickets
from match_summary ms
join batting_summary bts
using(matchID)
join bowling_summary bws
using(matchID)
group by ground;
/*Analysing the Batters*/
/* Top 10 Highest Scores of the tournament*/
select battername,team ,runs,balls,SR,4s,6s
from batting_summary bs
join player_info pi
on bs.battername=pi.name
order by runs desc limit 10;
/*Fifties scored in the tournament*/
select battername,team ,runs,balls,SR,4s,6s
from batting_summary bs
join player_info pi
on bs.battername=pi.name
where runs >= 50;
/*Top 5 players who scored highest runs & their batting figures 
along with the team they play for*/
select battername,team,
sum(runs) as Total_runs,
sum(4s) as Total_4s,
sum(6s) as Total_6s,
ceiling(avg(SR)) as Average_Strikerate
from batting_summary bs
join player_info pi
on bs.battername=pi.name
group by battername,team
order by Total_runs desc
limit 5;
/* Top 5 batters with Highest number of boundaries*/
select battername,
ceiling(avg(SR)) as Strike_rate,
sum(4s) as Number_of_4s,
sum(6s) as Number_of_6s,
sum(4s+6s) as Number_of_boundaries
 from batting_summary
 group by battername
 order by Number_of_boundaries desc limit 5;
/*Total runs scored at each batting position of all team*/
select battingPos,
sum(runs) as Total_runs
from batting_summary
group by battingPos;
/* Top 10 Players who have given highest number of notout innings*/
select battername,
count(*) as number_of_innings
from batting_summary
group by battername
order by number_of_innings desc
limit 10;
/*Compare the total runs scored by left handed batsmen and right handed batsmen*/
select battingStyle,
sum(runs) as Total_runs
from batting_summary bs
join player_info pi
on bs.battername=pi.name
group by battingStyle;
/*batting figures of players in different playing roles 
in the descending order of their Total runs*/
select playingRole,
sum(runs) as Total_runs,
sum(4s) as Total_4s,
sum(6s) as Total_6s,
ceiling(avg(SR)) as Average_Strikerate
from batting_summary bs
join player_info pi
on bs.battername=pi.name
group by playingRole
order by Total_runs desc;
/*Mention all the batters and who have Strike_rate Greater than 
the average economy of the tournament*/
select batterName,
ceiling(avg(SR)) as Strike_rate
from batting_summary
group by battername 
having Strike_rate > (select avg(SR) from batting_summary)
order by Strike_rate desc;

/*Analysing the Bowlers*/

/* Top 5 leading wicket takers and their bowling figures 
along with the team they play for 
primarily ordered by number of wickets in descending
secondarily ordered by number os runs given in the ascending*/
select bowlerName,team,
ceiling(avg(economy)) as economy,
sum(wickets) as Number_of_wickets,
sum(runs) as Total_runs_given,
sum(maiden) as Number_of_Maidens
from bowling_summary bs
join player_info pi
on bs.bowlerName=pi.name
group by bowlerName,team
order by Number_of_wickets desc,Total_runs_given
limit 5;
/* Top 5 bowlers who have given most number of Extras(Noball & wide combined)
and their average economy*/
select bowlerName,
sum(noBalls+wides) as Extras_given,
ceiling(avg(economy)) as avg_economy
from bowling_summary
group by bowlerName
order by Extras_given desc 
limit 5;
/*Top 5 most expensive bolwers as per their economy
(who have played more than 5 matches) and number of wickets taken by them*/
select bowlerName,
count(*) as numer_of_matches_played,
ceiling(avg(economy)) as average_economy,
sum(wickets) as Total_wickets_taken
from bowling_summary
group by bowlerName
having numer_of_matches_played>5
order by average_economy desc
limit 5;
/*Mention all the bowlers and who have economy lesser than 
the average economy of the tournament*/
select bowlerName,
ceiling(avg(economy)) as economy
from bowling_summary
group by bowlerName
having economy <(select avg(economy) from bowling_summary)
order by economy;
/* Top 5 Bowlers with highest number of maidens in the tournament*/
select bowlerName,
sum(maiden) as Number_of_maidens
from bowling_summary
group by bowlerName
order by Number_of_maidens desc
limit 5;
/* Fiver (five wicket taking) performances of the tournament*/
select bowlerName,team ,wickets,overs,runs,maiden
from bowling_summary bs
join player_info pi
on bs.bowlerName=pi.name
where wickets = 5;
/*Advanced Analysis*/

/*Scores given to batters as per their Strike_Rate*/
with CTE1 as
(select battername,
ceiling(avg(SR)) Strike_rate
from batting_summary
group by battername)
select *,
case when Strike_rate > 150 then 5
when Strike_rate > 120 then 4
when Strike_rate > 100 then 3
when Strike_rate > 80 then 2
else 1 end as Strike_score
from CTE1;
/*Scores given to bowlers as per their economy*/
 with CTE2 as
(select bowlerName,
ceiling(avg(economy)) economy
from bowling_summary
group by bowlerName)
select *,
case when economy > 10 then 1
when economy between 8 and 10 then 2
else 1 end as Economy_score
from CTE2;
/* Rank Batters of each team based on total runs scored by them*/
with CTE3 as
(select team,name,
sum(runs) as Total_runs
from batting_summary bs
join player_info pi
on pi.name=bs.battername
group by team,name)
select *,
rank() over(partition by team order by Total_runs desc ) as Batting_rank
from CTE3;
/* Rank bowlers of each team based on total Wickets taken by them*/
with CTE4 as
(select team,name,
sum(wickets) as Total_wickets
from bowling_summary bs
join player_info pi
on pi.name=bs.bowlerName
group by team,name)
select *,
rank() over(partition by team order by Total_wickets desc ) as Bowling_rank
from CTE4;
/*Create a view on Bowling figures of all the bowlers in the Tournament*/
create view Bowlers_stats as
(
select bowlerName,team,
sum(wickets) as Number_of_wickets,
ceiling(avg(economy)) as economy,
sum(runs) as Total_runs_given,
sum(maiden) as Number_of_Maidens
from bowling_summary bs
join player_info pi
on bs.bowlerName=pi.name
group by bowlerName,team
order by Number_of_wickets desc
);
/*Create a view on Batting figures of all the batters in the Tournament*/
create view Batters_stats as
(
select batterName,team,
sum(runs) as Number_of_runs,
ceiling(avg(SR)) as Strike_rate,
sum(4s) as Total_Number_of_4s,
sum(6s) as Total_number_of_6s
from batting_summary bs
join player_info pi
on bs.battername=pi.name
group by battername,team
order by Number_of_runs desc
);
/*Create a Stored Procedure to retrieve the bowling figures of a player 
in the tournament from Bowlers_stats using bowlerName*/
call Get_bowling_figures("Shreyanka Patil");
/*Create a Stored Procedure to retrieve the Batter figures of a player 
in the tournament from Batters_stats using battername*/
call Get_batting_figures("Hayley Matthews");
