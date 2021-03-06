<?php include('redirect.php'); ?>
<!DOCTYPE html>
<html>
<head>
    <title>12Urenloop Live</title>
    <link rel="stylesheet" type="text/css" href="vstyle.css" />

    <script type="text/javascript" src="lib/jquery-1.7.1.min.js"></script>
    <script type="text/javascript" src="lib/boxxy-interface.js"></script>
    <script type="text/javascript" src="http://live.12urenloop.be:8080/boxxy.js"></script>
    <script type="text/javascript" src="lib/interpolation.js"></script>
    <script type="text/javascript">
        window.onload = function() {
            var client = new Boxxy(),
                interpolation = new Interpolation(),
                scoreboard = $('#scoreboard').children().first();
            client.receivedConfig = function(config) {
                interpolation.init(config);
                var teams = client.getTeams();
                for(var idx in teams) {
                    var team = teams[idx];
                    var progress = interpolation.getCoords(team.id, shapes.line);
                    console.log(progress);
                    var elem = $('<tr></tr>').attr('id', team.id);
                    var progress = $('<span></span>').addClass('progress').width(progress.x * 90 + '%');
                    elem.append($('<td></td>').addClass('name').html('<span class="teamName">' + team.name + '</div>').append(progress));
                    elem.append($('<td></td>').addClass('score').html(team.laps));
                    scoreboard.append(elem);
                }
                
                setInterval(function() {
                    scoreboard.children().each(function(idx, elem) {
                        var team = teams[idx];
                        var progress = interpolation.getCoords(team.id, shapes.line);
                        $(elem).find('.progress').width(progress.x * 90 + '%');
                    });
                }, 100);
            }

            client.updatedPosition = function(message) {
                var teams = client.getTeams();
                scoreboard.children().each(function(idx, elem) {
                    var team = teams[idx];
                    var progress = interpolation.getCoords(team.id, shapes.line);
                    $(elem).find('.teamName').html(teams[idx].name);
                    $(elem).find('.score').html(teams[idx].laps);
                    $(elem).find('.progress').width(progress.x * 90 + '%');
                });
            }

            client.addedLap = function(message) {

            }

            client.connect('live.12urenloop.be');
        }
    </script>
</head>

<body>

<a id="logo" href="http://12urenloop.be/"><img src="assets/logo-100.png" /></a>
<div class="section-title">Volg live de score van de 12Urenloop!</div>
<div class="section-content">
    <!--<span style="width: 100%; display: inline-block; text-align: right;"><a id="autorefresh-toggle" href="#"> Toggle autorefresh</a></span>-->
    <table class="scoreboard" id="scoreboard">
        <tbody>
        </tbody>
    </table>
</div>

</body>

</html>
