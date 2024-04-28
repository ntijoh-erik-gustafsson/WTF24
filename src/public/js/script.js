document.addEventListener('DOMContentLoaded', function() {
    const add_genre_button = document.getElementById('add_genre');
    const genre_dropdown = document.getElementById('genre_dropdown');
    const genre_list = document.getElementById('genre_list');
    let genre_list_ids = [];

    // Extract genre IDs from the HTML and populate the genre_list_ids array
    const genre_divs = genre_list.children;
    for (let i = 0; i < genre_divs.length; i++) {
        const id = genre_divs[i].id.split('_')[1];
        genre_list_ids.push(id);

    }
    
    console.log(genre_list_ids)

    add_genre_button.addEventListener('click', add_genre);

    add_listeners();
    
    function add_genre() {
        // Get the selected genre ID
        const selected_genre_id = genre_dropdown.value;

        // Get the selected genre name
        const selected_genre_name = genre_dropdown.options[genre_dropdown.selectedIndex].text;

        // Check if the genre is already in the list
        if (!genre_list_ids.includes(selected_genre_id)) {
            // Create genre item
            const GENRE_ITEM = document.createElement('div');
            GENRE_ITEM.innerHTML = '<p>' + selected_genre_name + '</p>';

            // Assign ID to genre item based on genre ID
            GENRE_ITEM.id = 'genre_' + selected_genre_id;

            console.log(GENRE_ITEM.id)

            // Append genre item to visual genre list
            genre_list.appendChild(GENRE_ITEM);

            // Add the genre ID to the array
            genre_list_ids.push(selected_genre_id);

            // Add listener for remove button
            add_listener(selected_genre_id);
        }
    }

    function delete_genre(id) {
        console.log(id);
    
        // Remove the visual genre
        genre_list.removeChild(document.getElementById(id));
    
        // Remove the genre from the list
        let index = 0;
        while (index < genre_list_ids.length) {
            if (genre_list_ids[index] == id.charAt(id.length - 1)) {
                genre_list_ids.splice(index, 1);
            } else {
                index++; 
            }
        }
            
        console.log(genre_list_ids);
    }

    function add_listeners() {
        let number_of_remove_buttons = document.getElementById("genre_list").children.length-1;
        console.log(number_of_remove_buttons);

        genre_list_ids.forEach(function(genre_id) {
            // Add event listener to the remove button of each genre div
            document.getElementById("genre_" + genre_id).addEventListener("click", function() {
                delete_genre("genre_" + genre_id);
            });
        });
    }
        

    function add_listener(id) {
        // Create remove button
        const REMOVE_BUTTON = document.createElement('button');
        REMOVE_BUTTON.textContent = 'X';
        REMOVE_BUTTON.classList.add('remove_button');
        REMOVE_BUTTON.setAttribute('type', 'button');

        // Attach event listener to remove button
        REMOVE_BUTTON.addEventListener('click', function() {
            delete_genre("genre_" + id);
        });

        // Append remove button to genre item
        document.getElementById('genre_' + id).appendChild(REMOVE_BUTTON);
    }


    document.getElementById('release_form').addEventListener('submit', function() {
        const hiddenInput = document.createElement('input');
        hiddenInput.setAttribute('type', 'hidden');
        hiddenInput.setAttribute('name', 'genres');
        const genresWithoutQuotes = JSON.stringify(genre_list_ids.join(",")).replace(/"/g, '');
        hiddenInput.setAttribute('value', genresWithoutQuotes);
        this.appendChild(hiddenInput);
    });
});
