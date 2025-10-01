<?php 
session_start();
include('db.php'); ?>
<html>
    <head>
        <title>xPower Q</title>
        <style>
            .saveBtn{
                margin-top: 10px;
                width: 200px;
                height: 40px;
            }
        </style>
    </head>
    
    <body>
        <?php
        $textQuery = '';
        if(isset($_POST['btn_save'])){
            $textQuery = $_POST['textquery'];
            $sql_runQry = $mysqli->query($textQuery);
            
            echo '<span>'.$sql_runQry->num_rows.' found</span>';
        	echo '<table border="1"><tr style="background: antiquewhite;">';
        	
        	$fieldArray = [];
        	while ($fieldinfo = $sql_runQry -> fetch_field()) {
        	   array_push($fieldArray, $fieldinfo->name);
        		echo '<td>' . $fieldinfo->name . '</td>';
        	}
        	echo '</tr>';
            while($runQry = $sql_runQry->fetch_assoc()){
                
                echo '
                    <tr>';
                    foreach($fieldArray as $fieldNm){
                		echo '<td>' . $runQry[$fieldNm]. '</td>';
                	}
                    
                echo '        
                    </tr>
                ';
            }
            
            echo '</table>';
        }
            
        
        ?>

        <form action="db_new.php?55" method="POST" style="width: 100%; margin-top: 25px;">
            <label >Write your query here?</label>
            <textarea rows="15" name="textquery" style="width: 100%; "><?php echo $textQuery; ?></textarea>
            
            <input type="submit" class="saveBtn" name="btn_save" value="RUN" />
        </form>
    </body>
</html>