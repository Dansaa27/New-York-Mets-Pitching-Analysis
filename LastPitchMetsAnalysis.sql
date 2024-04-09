--Question 1 AVG Pitches Per at Bat Analysis


--1a AVG Pitches Per At Bat


SELECT AVG(Pitch_number) AvgNumofPitchesPerAtBat
FROM `smart-proxy-415101.nymets.lastpitch`;


--1b AVG Pitches Per At Bat Home Vs Away -> UNION ALL


SELECT
 'Home' AS TypeofGame,
 AVG(Pitch_number) AS AvgNumofPitchesPerAtBat
FROM `smart-proxy-415101.nymets.lastpitch`
WHERE home_team='NYM'
UNION ALL
SELECT
 'Away' AS TypeofGame,
 AVG(Pitch_number) AS AvgNumofPitchesPerAtBat
FROM `smart-proxy-415101.nymets.lastpitch`
WHERE away_team='NYM'


--1c AVG Pitches Per At Bat Lefty Vs Righty  -> Case Statement


SELECT
 AVG(Case When Batter_position = 'L' Then Pitch_number end) AS LeftyatBats,
 AVG(Case When Batter_position = 'R' Then Pitch_number end) AS RightyatBats
FROM `smart-proxy-415101.nymets.lastpitch`


--1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team -> Partition By


SELECT DISTINCT
 home_team,
 Pitcher_position,
 AVG(pitch_number) OVER (partition by home_team, Pitcher_position) AS Avgpitches
FROM `smart-proxy-415101.nymets.lastpitch`
WHERE away_team = 'NYM'


--1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts


with totlpitchsequence as (
 SELECT DISTINCT
   pitch_name,
   pitch_number,
 count(pitch_name) OVER (partition by pitch_name, pitch_number) AS PitchFrequency
 FROM `smart-proxy-415101.nymets.lastpitch`
 WHERE pitch_number < 11
),
pitchfrequencyrankquery as(
SELECT *,
 rank() OVER (partition by pitch_number order by PitchFrequency desc) AS PitchFruquencyRanking
FROM totlpitchsequence
)
SELECT *
FROM pitchfrequencyrankquery
WHERE PitchFruquencyRanking < 4


--1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings | Order in descending (LastPitchMets + MetsPitchingStats)


SELECT
 MP.Name,
 AVG(pitch_number) AS AVGPitches
FROM `smart-proxy-415101.nymets.lastpitch` AS LP
JOIN smart-proxy-415101.nymets.pitchingstats AS MP ON MP.pitcher_id = LP.pitcher
WHERE IP >= 20
group by MP.Name
order by AVG(pitch_number) DESC


--Question 2 Last Pitch Analysis


--2a Count of the Last Pitches Thrown in Desc Order


SELECT pitch_name, count(*)
FROM smart-proxy-415101.nymets.lastpitch
group by pitch_name
order by count(*) desc


--2b Count of the different last pitches Fastball or Offspeed


SELECT
 sum(case when pitch_name in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) AS Fastball,
 sum(case when pitch_name NOT in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) AS Offball,
FROM smart-proxy-415101.nymets.lastpitch


--2c Percentage of the different last pitches Fastball or Offspeed


SELECT
 100 * sum(case when pitch_name in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) / count(*) AS FastballPercent,
 100 * sum(case when pitch_name NOT in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) / count(*) AS OffballPercent,
FROM smart-proxy-415101.nymets.lastpitch


--2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher (LastPitchMets + MetsPitchingStats)


SELECT *
FROM(
 SELECT
   a.POS,
   a.pitch_name,
   a.timesthrown,
   RANK() OVER (Partition by a.POS order by a.timesthrown desc) AS PitchRank
 FROM (
   SELECT MP.POS, LP.pitch_name, count(*) AS timesthrown
   FROM `smart-proxy-415101.nymets.lastpitch` AS LP
   JOIN smart-proxy-415101.nymets.pitchingstats AS MP ON MP.pitcher_id = LP.pitcher
   group by MP.POS, LP.pitch_name
 ) a
) b
WHERE b.PitchRank <6


--Question 3 Homerun analysis


--3a What pitches have given up the most HRs (LastPitchMets)


SELECT pitch_name, count(*) AS HRs
FROM `smart-proxy-415101.nymets.lastpitch`
WHERE events = 'home_run'
group by pitch_name
order by count(*) desc


--3b Show HRs given up by zone and pitch, show top 5 most common


SELECT ZONE, pitch_name, count (*) AS HRs
FROM `smart-proxy-415101.nymets.lastpitch`
where events = 'home_run'
group by ZONE, pitch_name
order by count(*) desc
LIMIT 5


--3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher


SELECT MP.POS, LP.balls, LP.strikes, count(*) AS HRs
FROM `smart-proxy-415101.nymets.lastpitch` AS LP
JOIN smart-proxy-415101.nymets.pitchingstats AS MP ON MP.pitcher_id = LP.pitcher
where events = 'home_run'
group by MP.POS, LP.balls, LP.strikes
order by count(*) desc


--3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)


with hrcountpitchers as(
SELECT MP.name, LP.balls, LP.strikes, count(*) AS HRs
FROM `smart-proxy-415101.nymets.lastpitch` AS LP
JOIN smart-proxy-415101.nymets.pitchingstats AS MP ON MP.pitcher_id = LP.pitcher
where events = 'home_run' and IP >= 30
group by MP.name, LP.balls, LP.strikes
),
hrcountranks AS (
SELECT
 hcp.name,
 hcp.balls,
 hcp.strikes,
 hcp.HRs,
 rank() OVER (Partition by Name order by HRs desc) AS hrrank
FROM hrcountpitchers AS hcp
)
SELECT ht.Name, ht.balls, ht.strikes, ht.HRs
FROM hrcountranks AS ht
WHERE hrrank = 1


--Question 4 Kodai Senga


SELECT *
FROM `smart-proxy-415101.nymets.lastpitch` AS LP
JOIN smart-proxy-415101.nymets.pitchingstats AS MP ON MP.pitcher_id = LP.pitcher


--4a AVG Release speed, spin rate,  strikeouts, most popular zone ONLY USING LastPitchMets


SELECT
 AVG(release_speed) AvgReleaseSpeed,
 AVG(release_spin_rate) AvgSpinRate,
 Sum(case when events = 'strikeout' then 1 else 0 end) AS strkeouts,
 MAX(zones.zone) AS zone
FROM smart-proxy-415101.nymets.lastpitch AS LP
join(


 SELECT pitcher, zone, count(*) AS zonenum
 FROM smart-proxy-415101.nymets.lastpitch AS LP
 WHERE player_name = 'Senga, Kodai'
 group by pitcher, zone
 LIMIT 1


) zones on zones.pitcher = LP.pitcher
WHERE player_name = 'Senga, Kodai'


--4b top pitches for each infield position where total pitches are over 5, rank them


SELECT *
FROM (
SELECT pitch_name, count(*) AS timeshit, 'Third' AS position
FROM smart-proxy-415101.nymets.lastpitch
WHERE hit_location = 5 and player_name = 'Senga, Kodai'
group by pitch_name
UNION ALL
SELECT pitch_name, count(*) AS timeshit, 'Short' AS position
FROM smart-proxy-415101.nymets.lastpitch
WHERE hit_location = 6 and player_name = 'Senga, Kodai'
group by pitch_name
UNION ALL
SELECT pitch_name, count(*) AS timeshit, 'Second' AS position
FROM smart-proxy-415101.nymets.lastpitch
WHERE hit_location = 4 and player_name = 'Senga, Kodai'
group by pitch_name
UNION ALL
SELECT pitch_name, count(*) AS timeshit, 'First' AS position
FROM smart-proxy-415101.nymets.lastpitch
WHERE hit_location = 3 and player_name = 'Senga, Kodai'
group by pitch_name
) a
WHERE timeshit > 4
order by timeshit desc


--4c Show different balls/strikes as well as frequency when someone is on base


SELECT balls, strikes, count(*) AS frequency
FROM smart-proxy-415101.nymets.lastpitch
WHERE(on_3b is NOT NULL or on_2b is NOT NULL or on_1b is NOT NULL)
and player_name = 'Senga, Kodai'
group by balls, strikes
order by count(*) desc


--4d What pitch causes the lowest launch speed


SELECT pitch_name, avg(launch_speed) AS launchspeed
FROM smart-proxy-415101.nymets.lastpitch
WHERE player_name = 'Senga, Kodai'
group by pitch_name
order by avg(launch_speed)
LIMIT 1





