const person_name = document.getElementById('person_name');
const age = document.getElementById('age');
const hobbies = document.getElementById('hobbies');
// JSON string const 
jsonString = '{"name": "Jian", "age": 22, "hobbies": ["video games","soccer","reading","movies"]}';  
// Parse JSON string into a JavaScript object 
const jsonObject = JSON.parse(jsonString);  

console.log(jsonObject.name);  
console.log(jsonObject.age);   
console.log(jsonObject.hobbies);
 
person_name.textContent = "Name: "+JSON.stringify(jsonObject.name);
age.textContent = "Age: "+JSON.stringify(jsonObject.age);
hobbies.textContent = "Hobbies: "+JSON.stringify(jsonObject.hobbies);
// Convert JavaScript object back to JSON string 
const newJsonString = JSON.stringify(jsonObject); 
console.log(newJsonString);  // Output: {"name":"John","age":30,"city":"New York"}