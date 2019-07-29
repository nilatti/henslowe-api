import PropTypes from 'prop-types';

import React, {
  Component
} from 'react'

import {
  Button,
  Col,
  Form,
  Row
} from 'react-bootstrap'

import {
  Typeahead
} from 'react-bootstrap-typeahead';

class NewEntranceExitForm extends Component {
  state={
    characters: this.props.characters,
    line: '',
    page: '',
    notes: '',
    selectedCharacter: [],
    selectedStageExit: [],
    stageExits: this.props.stageExits,
    validated: false,
  }

  handleChange = (event) => {
    this.setState({
      [event.target.name]: event.target.value
    })
  }


  handleChangeCharacter = (e) => {
    if (e.length > 0) {
      this.setState({
        selectedCharacter: [e[0]]
      })
    }
  }

  handleChangeStageExit = (e) => {
    if (e.length > 0) {
      this.setState({
        selectedStageExit: [e[0]]
      })
    }
  }

  handleSubmit = (event) => {
    const form = event.currentTarget;
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    } else {
      this.processSubmit()
    }
    this.setState({
      validated: true
    })
  }

  processSubmit = () => {
    this.props.onFormSubmit({
      category: this.state.category,
      character_id: this.state.selectedCharacter[0].id,
      character_name: this.state.selectedCharacter[0].label,
      french_scene_id: this.props.frenchSceneId,
      line: this.state.line,
      page: this.state.page,
      notes: this.state.notes,
      stage_exit_id: this.state.selectedStageExit[0].id,
      stage_exit_name: this.state.selectedStageExit[0].label,
    }, "entrance_exit")
  }

  render() {
    const {
      validated
    } = this.state
    var characters = this.state.characters.map((character) => ({
      id: character.id,
      label: String(character.name)
    }))
    var stageExits = this.state.stageExits.map((stageExit) => ({
      id: stageExit.id,
      label: String(stageExit.name)
    }))
    return (
      <div>
      <Form
        noValidate
        onSubmit={e => this.handleSubmit(e)}
        validated={validated}
      >
        <Form.Group>
          <Form.Label>
            Stage exit
          </Form.Label>
          <Typeahead
            id="stage_exit"
            required
            options={stageExits}
            onChange={(selected) => {
              this.handleChangeStageExit(selected)
            }}
            selected={this.state.selectedStageExit}
            placeholder="Choose the exit"
          />
          <Form.Control.Feedback type="invalid">
              Stage exit is required
          </Form.Control.Feedback>
        </Form.Group>
        <Form.Group>
          <Form.Label>
            Character
          </Form.Label>
          <Typeahead
            id="character"
            required
            options={characters}
            onChange={(selected) => {
              this.handleChangeCharacter(selected)
            }}
            selected={this.state.selectedCharacter}
            placeholder="Choose the character"
          />
          <Form.Control.Feedback type="invalid">
              Character is required
          </Form.Control.Feedback>
        </Form.Group>
        <Form.Group>
          <Form.Label>
            Line number
          </Form.Label>
          <Form.Control
            id="line"
            type="number"
            name="line"
            onChange={this.handleChange}
            placeholder="line number"
            value={this.state.line}
          />
        </Form.Group>
        <Form.Group>
          <Form.Label>
            Page number
          </Form.Label>
          <Form.Control
            id="page"
            type="number"
            name="page"
            onChange={this.handleChange}
            placeholder="page number"
            value={this.state.page}
          />
        </Form.Group>
        <Form.Group controlId="category">
          <Form.Label>
            Category
          </Form.Label>
          <Form.Control
            as="select"
            name="category"
            onChange={this.handleChange}
            required
            value={this.state.category}
          >
            <option></option>
            <option value="Enter">Enter</option>
            <option value="Exit">Exit</option>
          </Form.Control>
        </Form.Group>
        <Form.Group>
          <Form.Label>
            Notes
          </Form.Label>
          <Form.Control
            as="textarea"
            id="notes"
            name="notes"
            onChange={this.handleChange}
            placeholder="Add notes, like whether they should bring a certain prop on."
            rows="3"
            type="textarea"
            value={this.state.notes}
          />
        </Form.Group>
        <Button type="submit" variant="primary" block>Submit</Button>
        <Button type="button" onClick={this.props.onFormClose} block>Cancel</Button>
      </Form>
      </div>
    )
  }
}

NewEntranceExitForm.propTypes = {
  characters: PropTypes.array.isRequired,
  frenchSceneId: PropTypes.number.isRequired,
  stageExits: PropTypes.array.isRequired,
  onFormClose: PropTypes.func.isRequired,
  onFormSubmit: PropTypes.func.isRequired,
}


export default NewEntranceExitForm
