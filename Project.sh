#!/bin/bash

# Function to initialize the game
initialize_game() {
    #read names for both players
    echo "Enter player 1's name:"
    read player1

    echo "Enter player 2's name:"
    read player2

    #read number of moves from user	
    echo "Enter the number of moves after which the game will conclude:"
    read num_moves

    # Ask user for game initialization option
    echo "Choose game initialization option:"
    echo "1. Start from scratch"
    echo "2. Load from file"
    read init_option

    #check the entered option	
    if [ $init_option -eq 1 ]; then
        echo "Enter the dimensions of the grid (NxN, where N can be 3, 4, or 5):"  #if user chose option 1 --> ask him about the size of the grid
        read grid_size
        initialize_grid $grid_size
    elif [ $init_option -eq 2 ]; then  
        echo "Enter the name of the file:"  #if user chose option 2 --> ask him about the name of the file
        read file_path
        load_from_file $file_path
    else   #else invalid choise --> exit (error handling)
        echo "Invalid option. Exiting..."
        exit 1
    fi
}

# Function to initialize the grid
initialize_grid() {
    size=$1
    for ((i=0; i<$(( size*size )); i++)); do
        grid[$i]="."   #initialize the gris with '.'
    done
    display_grid $size
}

# Function to display the grid
display_grid() {
    size=$1
    for ((i=0; i<$size; i++)); do
        for ((j=$(( i*size )); j<$(( i*size+$size )); j++)); do
            echo -n "|${grid[$j]}"   
        done
        echo "|"
    done
}

# Function to load grid from file
load_from_file() {
    local file=$1
    if [ -f "$file" ]; then
        mapfile -t content <"$file"  # Read file content into an array
        local size=$(( ${#content[@]} ))  # Determine grid size based on number of lines in the file
        
        for ((i = 0; i < size; i++)); do
            local row=${content[$i]}
            IFS='|' read -r -a marks <<<"$row"  # Split line into marks using '|' delimiter
            for ((j = 0; j < size; j++)); do
                grid[$(( i * size + j ))]=${marks[$j]}  # Assign marks to the grid
            done
        done
        grid_size=$size
        display_grid "$size"  # Display the loaded grid
    else
        echo "File not found. Exiting..."
        exit 1
    fi
}


# Function to handle player moves
handle_move() {
    player=$1
    move=$2
    case $move in
        1)
            echo "Player $player's move: Place your mark (e.g., 'row1 col1 (0 1)')"
            read -r row col
            if [[ ${grid[ $(( $row*$size +$col )) ]} == "." ]]; then   #if the index chosen clear '.' --> place player mark  
                grid[ $(( $row*$size+ $col )) ]=$player_mark  
                display_grid $size
            else
                echo "Cell already occupied. Try again."   
                handle_move $player $move
            fi
            ;;
        2)
            echo "Player $player's move: Remove your mark (e.g., 'row1 col1 (1 1)')"
            read -r row col
            if [[ ${grid[ $(( $row*$size + $col )) ]} == $player_mark ]]; then  #if the index chosen contain player mark --> remove mark (replace it with '.')
                grid[ $(( $row*$size+ $col )) ]="."
                display_grid $size
            else
                echo "No mark of player $player found in the specified cell. Try again."
                handle_move $player $move
            fi
            ;;
        3)
            echo "Player $player's move: Exchange rows (e.g., 'row1 row2(0 2)')"
            read -r row1 row2
            row1=$(( $row1 * $size )) #index of first cell in the first row entered
            row2=$(( $row2 * $size )) 
            for ((i=0; i<$size; i++)); do
                temp=("${grid[ $(( $row1 + $i )) ]}")
                grid[ $(( $row1 + $i )) ]="${grid[ $(( $row2 + $i )) ]}"  #replace each cell from row 1 with each cell in row 2
                grid[ $(( $row2 + $i )) ]="${temp}"
            done
            display_grid $size
            ;;
        4)
            echo "Player $player's move: Exchange columns (e.g., 'col1 col2 (1 2)')"
            read -r col1 col2
            for ((i=0; i<$size; i++)); do
                temp=("${grid[ $(( $col1 + $i * $size )) ]}")
                grid[ $(( $col1 + $i * $size )) ]="${grid[ $(( $col2 + $i * $size )) ]}" #replace each cell from col 1 with each cell in col 2
                grid[ $(( $col2 + $i * $size )) ]="${temp}"   #replace each cell from col 2 with each cell in col 1
            done
            display_grid $size
            ;;
        5)
            echo "Player $player's move: Exchange marks (e.g., 'row1 col1 row2 col2 (0 0 1 2)')"
            read -r row1 col1 row2 col2
            temp=${grid[$(( $row1*$size + $col1 ))]}
            grid[$(( $row1*$size + $col1 ))]=${grid[$(( $row2*$size + $col2 ))]}  #reaplace mark in index row1 col1  with mark in index row2 col2
            grid[$(( $row2*$size + $col2 ))]=$temp	#reaplace mark in index row2 col2  with mark in index row1 col1
            display_grid $size
            ;;
        *)
            echo "Invalid move. Try again."   #invalid input 
            handle_move $player
            ;;
    esac
}

# Function to calculate alignments for a player
calculate_alignments() {
    player_mark=$1
    alignments=0
	
    # Check horizontal alignments
    for ((i=0; i<$size; i++)); do
        flag=0
        
        for ((j=0; j< $size ; j++)); do
       				
            if [[ ${grid[ $(( i*size+j )) ]} != $player_mark ]]  #if index of row!= $player_mark --> no horizontal alignments
	    then
		flag=1
		break 1
	    fi	
  	done
	
        if [[ $flag -eq 0 ]]  #if flag still 0 --> ther is alignment
        then
             (( alignments++ )) 
        fi

    done	
 	
    # Check vertical alignments
    for ((i=0; i<$size; i++)); do
        flag=0
        for ((j=0; j<$size; j++)); do
            if [[ ${grid[ $(( i+j*size)) ]} != $player_mark ]]   #if index of col != $player_mark --> no vertical alignments
	    then
		flag=1
		break
	    fi	
  	done

        if [[ $flag -eq 0 ]]
        then
             (( alignments++ )) 
        fi   

    done
    
     # Check diagonal alignments
     #target each index in first diagnol
     flag=0
     for ((j=0; j<$size ; j++)); do
         if [[ ${grid[ $(( j*size+j )) ]} != $player_mark ]]  #if index of first diagonal != $player_mark --> no diagonal alignments in first diagonal
         then
	     flag=1
	     break
	 fi
	    	
     done

     if [[ $flag -eq 0 ]]
     then
          (( alignments++ )) 
     fi   
	
     flag=0
     #target each index in second diagnol
      for ((j=1; j<=$size ; j++)); do       							   								
          if [[ ${grid[ $(( j*size-j )) ]} != $player_mark ]]   #if index of second diagonal != $player_mark --> no diagonal alignments in second diagonal
          then
	      flag=1
	      break
	  fi
	    	
      done

      if [[ $flag -eq 0 ]]
      then
           (( alignments++ )) 
      fi   
	

    echo $alignments	
}

# Function to calculate penalties for a player
calculate_penalties() {
    player=$1
    case $move_option in
        3) echo 1 ;;
        4) echo 1 ;;
        5) echo 2 ;;
        *) echo 0 ;;
    esac
}

# Function to calculate and display scores
calculate_scores() {

    if [[ $move_option -eq 2 && $player == $player1 ]]  #give 1 point for a player chose option 2 (remove a mark)
    then
    	player1_score=$(( player1_score + 1 ))
    fi	
    
    if [[ $move_option -eq 2 && $player == $player2 ]]
    then
    	player2_score=$(( player2_score + 1 ))  	
    fi	
    	 
    player1_penalties=0
    player2_penalties=0
    # Calculate alignments and penalties for each player
    
    player1_alignments=$(calculate_alignments $player1_mark)  #calculate player1 alignments
    
    player2_alignments=$(calculate_alignments $player2_mark)  #calculate player2 alignments

    
    if [[ $player == $player1 ]]  #if its player 1 turn
    then
    	player1_penalties=$(calculate_penalties $player)  #calc penalties for player 1
    	player1_score=$(( player1_score + player1_alignments * 2 - player2_alignments * 3 - player1_penalties )) #calc score for player 1
    	
    else	
    	player2_penalties=$(calculate_penalties $player)
    	player2_score=$(( player2_score + player2_alignments * 2 - player1_alignments * 3 - player2_penalties ))
    fi

   
    echo "Player $player1's score: $player1_score"
    echo "Player $player2's score: $player2_score"
}

# Main function
main() {

    player1_score=0
    player2_score=0
    player1_mark='x'
    player2_mark='o'
  	
    initialize_game
    size=$grid_size
    
    for ((moves=1; moves<=num_moves; moves++)); do  #the game will continue untill reaches number of moves
        if (( moves % 2 != 0 )); then
            player=$player1
            player_mark=$player1_mark
        else
            player=$player2
            player_mark=$player2_mark
        fi

        echo "Move $moves:"
        echo "Player $player's turn"
        echo "Choose move option:"
        echo "1. Place your mark"
        echo "2. Remove your mark"
        echo "3. Exchange rows"
        echo "4. Exchange columns"
        echo "5. Exchange marks"
        
        read move_option
        
        #if option = 2 --> we need to check if player has at least one mark in the board wo he can remove it -- else the move isnt valid
        if [[ $move_option -eq 2 ]] 
        then
            flag=0
	    for ((j=0; j<$(( size*size )) ; j++))
	    do 
	       if [[ ${grid[$j]} == $player_mark ]]
	       then	
	           flag=1	
	           break 
	       fi	
	     
            done
        
       	    if [[ $flag -eq 0 ]]		
	    then
	    	echo "You have no marks in the board to remove! chose another option."
	       (( moves-- ))
	       continue	    	
	     fi
	 fi
	 
        handle_move $player $move_option
        calculate_scores
    done

    echo "Game concluded after $num_moves moves."
    
    if [[ $player1_score -gt $player2_score ]]
    then 
     	echo "$player1 wins the game !"
     	
    elif [[ $player2_score -gt $player1_score ]]
    then
    	echo "$player2 wins the game !"	
    else
    	echo "Its a tied match !"
    
    fi		
}

# Start the game
main
